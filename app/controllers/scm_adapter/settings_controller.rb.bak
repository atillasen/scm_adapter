# frozen_string_literal: true
class ScmAdapter::SettingsController < ApplicationController
  before_action :require_admin

  def index
    @settings = Setting.plugin_scm_adapter || {}
  end
end
