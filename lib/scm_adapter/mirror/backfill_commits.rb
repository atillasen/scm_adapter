# frozen_string_literal: true

require "open3"

module ScmAdapter
  module Mirror
    class BackfillCommits
      def initialize(link:, logger: defined?(Rails) ? Rails.logger : Logger.new($stdout), skip_sync: false)
        @link = link
        @project = link.project
        @logger = logger
        @mapping = ScmAdapter::Sync::Mapping.new(project: @project)
        @parser = ScmAdapter::Sync::CloseKeywordParser.new(allowed_keywords: @mapping.close_keywords)
        @skip_sync = skip_sync
      end

      def run
        sync_mirror! unless @skip_sync
        imported = 0
        commits_from_git.each do |commit|
          imported += process_commit(commit)
        end
        imported
      end

      private

      def sync_mirror!
        ScmAdapter::MirrorSyncJob.new.perform(
          project_id: @link.project_id,
          provider: @link.provider,
          remote_full_path: @link.remote_full_path,
          remote_project_id: @link.remote_project_id
        )
      end

      def commits_from_git
        cmd = ["git", "-C", mirror_path, "log", "--all", "--date-order", "--pretty=format:%H%x1f%an%x1f%ct%x1f%B%x1e"]
        stdout, stderr, status = Open3.capture3(*cmd)
        raise "git log failed: #{stderr.presence || stdout}" unless status.success?

        stdout.split("\x1e").filter_map do |entry|
          next if entry.strip.empty?
          sha, author, ts, message = entry.split("\x1f", 4)
          next unless sha
          { sha: sha, author: author, timestamp: ts.to_i, message: message.to_s }
        end
      end

      def process_commit(commit)
        message = commit[:message].to_s
        issue_ids = @parser.extract_issue_ids(message)
        return 0 if issue_ids.empty?

        created = 0
        issue_ids.each do |iid|
          issue = Issue.find_by(id: iid, project_id: @project.id)
          next unless issue
          existing = ScmAdapter::CommitEvent.find_by(issue_id: issue.id, sha: commit[:sha])
          branch = branch_for(commit[:sha])

          if existing
            if existing.branch.blank? && branch.present?
              existing.update(branch: branch)
            end
            next
          end

          update_issue_status(issue)
          ScmAdapter::CommitEvent.create!(
            issue_id: issue.id,
            provider: @link.provider,
            sha: commit[:sha],
            author: ScmAdapter::AuthorResolver.resolve(commit[:author]),
            url: commit_url(commit[:sha]),
            message: message,
            pushed_at: Time.at(commit[:timestamp]),
            branch: branch
          )
          created += 1
        end
        created
      rescue StandardError => e
        @logger&.warn("[scm_adapter][backfill] project=#{@project.id} sha=#{commit[:sha]} error=#{e.message}")
        0
      end

      def update_issue_status(issue)
        status_name = @mapping.issue_status_map["closed"] || "Closed"
        target = @mapping.redmine_status_id_by_name(status_name) || issue.status_id
        issue.init_journal(User.anonymous, "Auto-Status via Close-Keyword (Backfill)")
        issue.status_id = target
        issue.save!
      end

      def mirror_root
        cfg = Setting.plugin_scm_adapter.to_h
        cfg["mirror_base_path"].presence || "/usr/src/redmine/git-mirrors"
      end

      def mirror_path
        File.join(mirror_root, @link.provider, "#{@link.remote_full_path}.git")
      end

      def commit_url(sha)
        cfg = Setting.plugin_scm_adapter.to_h
        base, path = case @link.provider
                     when "gitlab"
                       [cfg["gitlab_base_url"].presence || cfg["gitlab_clone_base_url"] || "https://gitlab.com",
                        "#{@link.remote_full_path}/-/commit/#{sha}"]
                     when "github"
                       [cfg["github_clone_base_url"].presence || "https://github.com",
                        "#{@link.remote_full_path}/commit/#{sha}"]
                     else
                       [nil, nil]
                     end
        return nil unless base.present? && @link.remote_full_path.present?

        base = base.sub(%r{/$}, "")
        "#{base}/#{path}"
      end

      def branch_for(sha)
        stdout, _stderr, status = Open3.capture3("git", "-C", mirror_path, "for-each-ref", "--contains", sha, "refs/heads", "--format=%(refname:short)")
        return nil unless status.success?

        stdout.split("\n").reject(&:blank?).first
      rescue StandardError
        nil
      end
    end
  end
end
