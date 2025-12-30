# frozen_string_literal: true
class ScmAdapter::Webhooks::GithubController < ApplicationController
  before_action :verify_signature!
  skip_before_action :verify_authenticity_token

  def create
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status = :ok
    error  = nil
    project = nil
    event = request.headers["X-GitHub-Event"].to_s
    unless plugin_webhooks_enabled?
      status = :error
      return render json: {
        ok: false,
        error: I18n.t("scm_adapter.errors.plugin_webhooks_disabled")
      }, status: :forbidden
    end

    raw_body = request.raw_post
    payload = JSON.parse(raw_body) rescue {}

    link = find_link_from_payload(payload, provider: "github")
    if link == :conflict
      status = :error
      render json: { ok: false, error: "Mehrere Projekt-Links fuer dieses Repo gefunden" }, status: :conflict
      return
    elsif link.nil?
      status = :error
      render json: { ok: false, error: "Projekt nicht gefunden oder nicht verknuepft" }, status: :not_found
      return
    end

    project = link.project
    enqueue_mirror_sync(link, provider: "github")

    dispatcher = ScmAdapter::Sync::Dispatcher.new(project: project)

    case event
    when "push"
      branch = extract_branch(payload["ref"])
      (payload["commits"] || []).each do |c|
        dispatcher.handle_commit(
          commit: {
            provider: "github",
            message: c["message"].to_s,
            sha: c["id"],
            url: c["url"],
            author: c.dig("author", "name") || c.dig("committer", "name"),
            timestamp: c["timestamp"],
            branch: branch
              },
              remote: {
                remote_project_id: link.remote_project_id,
                remote_full_path: link.remote_full_path
              }
        )
      end
    when "pull_request"
      action = payload.dig("action")
      state  = case action
               when "closed"
                 payload.dig("pull_request", "merged") ? "merged" : "closed"
               when "opened", "synchronize" then "in_progress"
               else "in_progress"
               end
      status_id = dispatcher.handle_merge_status(state: state)
      pr = payload["pull_request"] || {}
      dispatcher.handle_commit(
        commit: {
          provider: "github",
          message: pr["body"].to_s,
          sha: pr["head"]&.dig("sha"),
          url: pr["html_url"],
          author: pr.dig("user", "login"),
          timestamp: pr["updated_at"],
          branch: pr.dig("head", "ref"),
          merge_request_title: pr["title"],
          merge_request_url: pr["html_url"],
          merge_request_iid: pr["number"].to_s
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
      provider: "github",
      event: event,
      project: project,
      status: status,
      error: error,
      start_time: start_time
    )
  end

  private

  def plugin_webhooks_enabled?
    settings = Setting.plugin_scm_adapter.to_h
    mode = settings.fetch("github_webhook_mode", settings.fetch("webhook_mode", "both")).to_s
    mode == "both" || mode == "plugin_only"
  end

  def verify_signature!
    secret = Setting.plugin_scm_adapter.to_h.fetch("github_webhook_secret", "").to_s
    head :unauthorized and return if secret.empty?

    signature = request.headers["X-Hub-Signature-256"].to_s
    head :unauthorized and return unless signature.start_with?("sha256=")

    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post)
    provided = signature.sub("sha256=", "")

    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(provided, expected)
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
    repo = payload["repository"] || {}
    full = repo["full_name"]
    rid  = repo["id"].to_s if repo.key?("id")

    scope = ScmAdapter::ProjectLink.where(provider: provider)

    if rid.present?
      by_id = scope.where(remote_project_id: rid)
      return :conflict if by_id.count > 1
      return by_id.first if by_id.exists?
    end

    by_path = scope.where(remote_full_path: full)
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
