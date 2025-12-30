# frozen_string_literal: true
class ScmAdapter::Webhooks::GitlabController < ApplicationController
  before_action :verify_token!
  skip_before_action :verify_authenticity_token

  def create
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status = :ok
    error  = nil
    project = nil
    event = request.headers["X-Gitlab-Event"].to_s
    unless plugin_webhooks_enabled?
      status = :error
      return render json: {
        ok: false,
        error: I18n.t("scm_adapter.errors.plugin_webhooks_disabled")
      }, status: :forbidden
    end

    payload = JSON.parse(request.raw_post) rescue {}

    link = find_link_from_payload(payload, provider: "gitlab")
    if link == :conflict
      status = :error
      render json: { ok: false, error: I18n.t("scm_adapter.errors.project_link_conflict") }, status: :conflict
      return
    elsif link.nil?
      status = :error
      render json: { ok: false, error: I18n.t("scm_adapter.errors.project_link_not_found") }, status: :not_found
      return
    end

    project = link.project
    enqueue_mirror_sync(link, provider: "gitlab")

    dispatcher = ScmAdapter::Sync::Dispatcher.new(project: project)

    case event
    when "Push Hook"
      commits = payload["commits"] || []
      branch  = extract_branch(payload["ref"])
      commits.each do |c|
        dispatcher.handle_commit(
          commit: {
            provider: "gitlab",
            message: c["message"].to_s,
            sha: c["id"],
            url: c["url"],
            author: c.dig("author", "name"),
            timestamp: c["timestamp"],
            branch: branch
              },
              remote: {
                remote_project_id: link.remote_project_id,
                remote_full_path: link.remote_full_path
              }
        )
      end
    when "Merge Request Hook"
      state = payload.dig("object_attributes", "state")
      status_id = dispatcher.handle_merge_status(state: state)
      # Beispiel: MR bezieht sich per Beschreibung auf Issue
      mr = payload["object_attributes"] || {}
      dispatcher.handle_commit(
        commit: {
          provider: "gitlab",
          message: mr["description"].to_s,
          sha: mr["last_commit"]&.dig("id"),
          url: mr["url"] || mr["web_url"],
          author: mr.dig("author_id") ? payload.dig("user", "name") : nil,
          timestamp: mr["updated_at"] || mr["last_edited_at"],
          branch: mr["source_branch"],
          merge_request_title: mr["title"],
          merge_request_url: mr["url"] || mr["web_url"],
          merge_request_iid: mr["iid"].to_s
              },
              remote: {
                remote_project_id: link.remote_project_id,
                remote_full_path: link.remote_full_path
              }
      )
    end

    render json: { ok: true }
  rescue => e
    status = :error
    error = e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  ensure
    log_webhook_metric(
      provider: "gitlab",
      event: event,
      project: project,
      status: status,
      error: error,
      start_time: start_time
    )
  end

  private

  def verify_token!
    cfg = Setting.plugin_scm_adapter.to_h
    secret = cfg.fetch("gitlab_webhook_secret", "").to_s
    head :unauthorized and return if secret.empty?

    provided = request.headers["X-Gitlab-Token"].to_s
    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(provided, secret)
  end

  def plugin_webhooks_enabled?
    settings = Setting.plugin_scm_adapter.to_h
    mode = settings.fetch("gitlab_webhook_mode", settings.fetch("webhook_mode", "both")).to_s
    mode == "both" || mode == "plugin_only"
  end

  def enqueue_mirror_sync(link, provider:)
    run_job(ScmAdapter::MirrorSyncJob,
      project_id: link.project_id,
      provider: provider,
      remote_full_path: link.remote_full_path,
      remote_project_id: link.remote_project_id)
  end

  def run_job(job_class, **args)
    ScmAdapter::JobRunner.run(job_class, **args)
  end

  def find_link_from_payload(payload, provider:)
    proj = payload["project"] || {}
    repo = payload["repository"] || {}
    path = proj["path_with_namespace"] || repo["full_name"]
    rid  = proj["id"].to_s if proj.key?("id")

    scope = ScmAdapter::ProjectLink.where(provider: provider)

    if rid.present?
      by_id = scope.where(remote_project_id: rid)
      return :conflict if by_id.count > 1
      return by_id.first if by_id.exists?
    end

    by_path = scope.where(remote_full_path: path)
    return :conflict if by_path.count > 1
    by_path.first
  end

  def extract_branch(ref)
    ref.to_s.sub(%r{\Arefs/heads/}, "")
  end

  def log_webhook_metric(provider:, event:, project:, status:, error:, start_time:)
    return unless start_time

    ScmAdapter::Instrumentation.emit(
      event: "webhook.#{provider}",
      status: status,
      duration_ms: ScmAdapter::Instrumentation.duration_ms(start_time),
      tags: {
        provider: provider,
        event: event.presence || "unknown",
        project_id: project&.id,
        queue: "webhooks"
      },
      error: error
    )
  end
end
