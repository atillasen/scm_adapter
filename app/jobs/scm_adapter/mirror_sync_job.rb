# frozen_string_literal: true

require "uri"

class ScmAdapter::MirrorSyncJob < ActiveJob::Base
  include ScmAdapter::JobInstrumentation

  queue_as :mirror

  def perform(project_id:, provider:, remote_full_path:, remote_project_id: nil)
    project = Project.find(project_id)
    cfg = Setting.plugin_scm_adapter.to_h
    integration = integration_for(project_id: project.id, provider: provider)

    mirror_root = cfg["mirror_base_path"].presence || "/usr/src/redmine/git-mirrors"
    git_bin = cfg["git_binary"].presence || "git"
    ssl_verify = ENV.fetch("SCM_ADAPTER_SSL_VERIFY", "true") != "false"
    ca_file = ENV["SCM_ADAPTER_CA_FILE"]

    clone_base = integration&.clone_base_url.presence || clone_base_url(cfg: cfg, provider: provider)
    raise "clone base url missing for #{provider}" if clone_base.to_s.strip.empty?
    token = integration&.token.presence || cfg["#{provider}_token"]
    clone_url = build_clone_url(clone_base, remote_full_path, provider: provider, token: token)

    mirror = ScmAdapter::Mirror::Sync.new(
      mirror_root: mirror_root,
      provider: provider,
      remote_full_path: remote_full_path,
      clone_url: clone_url,
      git_binary: git_bin,
      ssl_verify: ssl_verify,
      ca_file: ca_file
    )

    mirror_path = mirror.sync!
    ScmAdapter::RepositoryManager.new(
      project: project,
      mirror_path: mirror_path,
      identifier: provider_identifier(provider)
    ).ensure_git_repository!
  end

  private

  def provider_identifier(provider)
    provider.to_s == "gitlab" ? "gitlab" : "github"
  end

  def integration_for(project_id:, provider:)
    ScmAdapter::IntegrationSetting.find_by(project_id: project_id, provider: provider)
  end

  def clone_base_url(cfg:, provider:)
    case provider.to_s
    when "gitlab"
      cfg["gitlab_clone_base_url"].presence || cfg["gitlab_base_url"].to_s
    when "github"
      cfg["github_clone_base_url"].presence || "https://github.com"
    else
      ""
    end
  end

  def build_clone_url(base, path, provider:, token: nil)
    base = base.to_s.sub(%r{/+$}, "")
    url = "#{base}/#{path}.git"
    return url if token.to_s.empty?

    uri = URI.parse(url)
    user = provider.to_s == "gitlab" ? "oauth2" : "x-access-token"
    uri.user = user
    uri.password = token
    uri.to_s
  end
end
