# frozen_string_literal: true
class ScmAdapter::GithubSyncJob < ActiveJob::Base
  include ScmAdapter::JobInstrumentation

  queue_as :webhooks

  def perform(project_id:, full_name:)
    project = Project.find(project_id)
    cfg     = Setting.plugin_scm_adapter
    client  = ScmAdapter::Clients::GithubClient.new(
      base_url: cfg["github_base_url"],
      token: cfg["github_token"]
    )
    issues = client.issues(full_name, state: "open", per_page: 50)
    sync_issues(project, issues)
  end

  private

  def sync_issues(project, issues)
    mapping = ScmAdapter::Sync::Mapping.new(project: project)
    issues.each do |remote|
      dispatcher = ScmAdapter::Sync::Dispatcher.new(project: project)
      dispatcher.handle_commit(commit: {
        provider: "github",
        message: remote["body"].to_s,
        sha: remote.dig("head", "sha"),
        url: remote["html_url"],
        author: remote.dig("user", "login"),
        timestamp: remote["updated_at"]
      })
    end
  end
end
