# frozen_string_literal: true

require "open3"

module ScmAdapter
  module Mirror
    class HealthCheck
      def initialize(logger: defined?(Rails) ? Rails.logger : Logger.new($stdout))
        @logger = logger
      end

      def check_all(fix: false)
        ScmAdapter::ProjectLink.find_each.map do |link|
          check_link(link, fix: fix)
        end
      end

      private

      def check_link(link, fix:)
        path = mirror_path_for(link)
        messages = []
        status = :ok

        if File.directory?(path)
          head = git(["-C", path, "rev-parse", "--short", "HEAD"])
          messages << "mirror ok head=#{head}"
          if fix
            git(["-C", path, "fetch", "--all", "--prune"])
            messages << "mirror fetched"
          end
        else
          status = :error
          messages << "mirror missing at #{path}"
          if fix
            mirror_sync(link)
            status = :ok
            messages << "mirror synced"
          end
        end

        repo = find_repository(link)
        if repo
          if repo.url != path || repo.root_url != path
            messages << "repo path mismatch (url=#{repo.url})"
            if fix
              repo.update!(url: path, root_url: path)
              messages << "repo path updated"
            else
              status = :error
            end
          end
        else
          messages << "no repository configured for project"
          status = :error
        end

        log(status, link, messages)
        { project: link.project&.identifier || link.project_id, provider: link.provider, status: status, message: messages.join("; ") }
      rescue StandardError => e
        log(:error, link, ["error: #{e.message}"])
        { project: link.project&.identifier || link.project_id, provider: link.provider, status: :error, message: e.message }
      end

      def mirror_sync(link)
        ScmAdapter::MirrorSyncJob.new.perform(
          project_id: link.project_id,
          provider: link.provider,
          remote_full_path: link.remote_full_path,
          remote_project_id: link.remote_project_id
        )
      end

      def find_repository(link)
        repos = Repository.where(project_id: link.project_id, type: "Repository::Git").to_a
        repos.find { |r| r.url.to_s.start_with?(mirror_root) } ||
          repos.find { |r| r.identifier == link.provider } ||
          repos.first
      end

      def git(args)
        stdout, stderr, status = Open3.capture3(git_env, "git", *args)
        raise stderr.presence || stdout unless status.success?

        stdout.strip
      end

      def git_env
        env = {}
        verify = ENV.fetch("SCM_ADAPTER_SSL_VERIFY", "true") != "false"
        env["GIT_SSL_NO_VERIFY"] = "1" unless verify
        env["GIT_SSL_CAINFO"] = ENV["SCM_ADAPTER_CA_FILE"] if ENV["SCM_ADAPTER_CA_FILE"].present?
        env
      end

      def mirror_root
        cfg = Setting.plugin_scm_adapter.to_h
        cfg["mirror_base_path"].presence || "/usr/src/redmine/git-mirrors"
      end

      def mirror_path_for(link)
        File.join(mirror_root, link.provider, "#{link.remote_full_path}.git")
      end

      def log(status, link, messages)
        @logger&.public_send(status == :ok ? :info : :warn,
          "[scm_adapter][mirror_health] project=#{link.project_id} provider=#{link.provider} status=#{status} #{messages.join('; ')}")
      rescue StandardError
        # never raise from logging
      end
    end
  end
end
