# frozen_string_literal: true

class ScmAdapter::CommentBackJob < ActiveJob::Base
  include ScmAdapter::JobInstrumentation

  queue_as :comment_back

  def perform(provider:, remote_project_id:, remote_full_path:, sha:, issue_id:)
    issue = Issue.find_by(id: issue_id)
    return unless issue

    cfg = Setting.plugin_scm_adapter.to_h
    return unless cfg["comment_back_enabled"]

    case provider.to_s
    when "gitlab"
      client = ScmAdapter::Clients::GitlabClient.new(
        base_url: cfg["gitlab_base_url"],
        token: cfg["gitlab_token"]
      )
      client.post_commit_comment(remote_project_id, sha, comment_body(issue)) if remote_project_id.present?
    when "github"
      client = ScmAdapter::Clients::GithubClient.new(
        base_url: cfg["github_base_url"],
        token: cfg["github_token"]
      )
      client.post_commit_comment(remote_full_path, sha, comment_body(issue)) if remote_full_path.present?
    end
  end

  private

  def comment_body(issue)
    "Closed in Redmine as ##{issue.id} (Status: #{issue.status&.name})"
  end
end
