# frozen_string_literal: true

module ScmAdapter
  module CommentBackHelper
    def scm_adapter_remote_comments(project:, repository:, revision:)
      cfg = Setting.plugin_scm_adapter.to_h
      provider = repository.identifier.to_s.include?("github") ? "github" : "gitlab"
      link = ScmAdapter::ProjectLink.find_by(project_id: project.id, provider: provider)
      return [] unless link

        begin
        case provider
        when "gitlab"
          client = ScmAdapter::Clients::GitlabClient.new(
            base_url: cfg["gitlab_base_url"],
            token: cfg["gitlab_token"]
          )
          comments = (client.list_commit_comments(link.remote_project_id, revision) || [])
          comments.sort_by { |c| c["created_at"].to_s }.reverse.map do |c|
              body = c["note"].to_s
              marker_match = body.match(/\[redmine_user:(.+?)\]/)
              if marker_match
                author = marker_match[1]
                body = body.sub(marker_match[0], "").strip
              else
                author = c.dig("author", "name").presence || c.dig("author", "username")
              end
            {
              author: author,
              body: body,
              created_at: c["created_at"]
            }
          end
        when "github"
          client = ScmAdapter::Clients::GithubClient.new(
            base_url: cfg["github_base_url"],
            token: cfg["github_token"]
          )
          comments = (client.list_commit_comments(link.remote_full_path, revision) || [])
          comments.sort_by { |c| c["created_at"].to_s }.reverse.map do |c|
              body = c["body"].to_s
              marker_match = body.match(/\[redmine_user:(.+?)\]/)
              if marker_match
                author = marker_match[1]
                body = body.sub(marker_match[0], "").strip
              else
                author = c.dig("user", "login").presence || c.dig("author", "login")
              end
            {
              author: author,
              body: body,
              created_at: c["created_at"]
            }
          end
        else
          []
        end
      rescue => e
        Rails.logger.warn("[scm_adapter] remote comments fetch failed: #{e.message}") if defined?(Rails)
        []
      end
    end
  end
end
