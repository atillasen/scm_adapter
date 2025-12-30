# frozen_string_literal: true
class ScmAdapter::GitlabSyncJob < ActiveJob::Base
  include ScmAdapter::JobInstrumentation

  queue_as :webhooks

  def perform(project_id:, remote_project_id:)
    project = Project.find(project_id)
    cfg     = Setting.plugin_scm_adapter
    client  = ScmAdapter::Clients::GitlabClient.new(
      base_url: cfg["gitlab_base_url"],
      token: cfg["gitlab_token"]
    )
    issues = client.list_issues(remote_project_id, { state: "opened", per_page: 50 })
    sync_issues(project, issues)
  end

  private

  def sync_issues(project, issues)
    mapping = ScmAdapter::Sync::Mapping.new(project: project)
    issues.each do |remote|
      # Beispiel: Bei gefundenem "Fixes #ID" Kommentar in Beschreibung Status setzen
      dispatcher = ScmAdapter::Sync::Dispatcher.new(project: project)
      dispatcher.handle_commit(commit: {
        provider: "gitlab",
        message: remote["description"].to_s,
        sha: remote.dig("last_commit", "id"),
        url: remote["web_url"] || remote["url"],
        author: remote.dig("author", "name") || remote.dig("author", "username"),
        timestamp: remote["updated_at"] || remote["last_edited_at"]
      })
    end
  end
end
