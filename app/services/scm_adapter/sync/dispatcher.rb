# frozen_string_literal: true
module ScmAdapter
  module Sync
    class Dispatcher
      def initialize(project:)
        @project  = project
        @mapping  = Mapping.new(project: project)
        @parser   = CloseKeywordParser.new(allowed_keywords: @mapping.close_keywords)
      end

      # Beispiel: Aufgerufen durch Webhook (Push/MR/PR)
      def handle_commit(commit:, remote: {})
        message = commit[:message].to_s
        parsed = @parser.extract_issue_ids(message)
        issue_ids = parsed[:ids]
        close_keyword = parsed[:close_keyword]
        issue_ids.each do |iid|
          issue = Issue.find_by(id: iid, project_id: @project.id)
          next unless issue

          if close_keyword
            status_name = @mapping.issue_status_map["closed"] || "Closed"
            target = @mapping.redmine_status_id_by_name(status_name) || issue.status_id
            if target && target != issue.status_id
              issue.init_journal(User.anonymous, "Auto-Status via Close-Keyword")
              issue.status_id = target
              issue.save!
            end
          end

          ScmAdapter::CommitEvent.create!(
            issue_id: issue.id,
            provider: commit[:provider],
            sha: commit[:sha],
            author: ScmAdapter::AuthorResolver.resolve(commit[:author]),
            url: commit[:url],
            message: message,
            pushed_at: commit[:timestamp],
            branch: commit[:branch],
            merge_request_title: commit[:merge_request_title],
            merge_request_url: commit[:merge_request_url],
            merge_request_iid: commit[:merge_request_iid]
          )

          enqueue_comment_back(commit: commit, remote: remote, issue: issue)
        end
      end

      def handle_merge_status(state:)
        status_name = case state
                      when "merged" then @mapping.issue_status_map["merged"]
                      when "closed" then @mapping.issue_status_map["closed"]
                      when "opened" then @mapping.issue_status_map["opened"]
                      else @mapping.issue_status_map["in_progress"]
                      end || "In Progress"
        @mapping.redmine_status_id_by_name(status_name)
      end

      private

      def enqueue_comment_back(commit:, remote:, issue:)
        return if commit[:sha].to_s.empty?
        cfg = Setting.plugin_scm_adapter.to_h
        enabled = cfg["comment_back_enabled"] == true || cfg["comment_back_enabled"].to_s == "1"
        return unless enabled

        ScmAdapter::JobRunner.run(
          ScmAdapter::CommentBackJob,
          provider: commit[:provider],
          remote_project_id: remote[:remote_project_id],
          remote_full_path: remote[:remote_full_path],
          sha: commit[:sha],
          issue_id: issue.id
        )
      end
    end
  end
end
