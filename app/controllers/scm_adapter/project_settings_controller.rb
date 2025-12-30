# frozen_string_literal: true

class ScmAdapter::ProjectSettingsController < ApplicationController
  before_action :find_project
  before_action :authorize

  accept_api_auth :update

  def edit
    @gitlab_integration = integration_for("gitlab")
    @github_integration = integration_for("github")
  end

  def update
    upsert_integration("gitlab", params.dig(:gitlab, :clone_base_url))
    upsert_integration("github", params.dig(:github, :clone_base_url))
    flash[:notice] = I18n.t("scm_adapter.flashes.project_settings_updated")
    redirect_to project_scm_adapter_settings_path(@project)
  rescue => e
    flash[:error] = e.message
    redirect_to project_scm_adapter_settings_path(@project)
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def integration_for(provider)
    ScmAdapter::IntegrationSetting.find_by(project_id: @project.id, provider: provider)
  end

  def upsert_integration(provider, clone_base_url)
    record = integration_for(provider) || ScmAdapter::IntegrationSetting.new(project: @project, provider: provider, base_url: default_base(provider))
    record.clone_base_url = clone_base_url if clone_base_url.present?
    record.base_url ||= default_base(provider)
    record.save!
  end

  def default_base(provider)
    cfg = Setting.plugin_scm_adapter.to_h
    case provider
    when "gitlab" then cfg["gitlab_base_url"]
    when "github" then cfg["github_base_url"]
    else ""
    end
  end
end
