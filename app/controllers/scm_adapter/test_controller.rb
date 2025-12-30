# frozen_string_literal: true
class ScmAdapter::TestController < ApplicationController
  before_action :require_admin
  accept_api_auth :gitlab, :github

  def gitlab
    cfg = Setting.plugin_scm_adapter
    client = ScmAdapter::Clients::GitlabClient.new(
      base_url: cfg["gitlab_base_url"],
      token: cfg["gitlab_token"],
      webhook_secret: cfg["gitlab_webhook_secret"]
    )
    projects = client.list_projects(per_page: 1)
    render json: { ok: true, example_project: projects.first }, status: :ok
  rescue => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end

  def github
    cfg = Setting.plugin_scm_adapter
    client = ScmAdapter::Clients::GithubClient.new(
      base_url: cfg["github_base_url"],
      token: cfg["github_token"],
      webhook_secret: cfg["github_webhook_secret"]
    )
    me = client.send(:get_json, "/user")
    render json: { ok: true, login: me["login"] }, status: :ok
  rescue => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end
end

