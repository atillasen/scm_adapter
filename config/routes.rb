# frozen_string_literal: true
Rails.application.routes.draw do
  scope module: "scm_adapter", path: "scm_adapter" do
    get  "settings", to: "settings#index"
    post "test/gitlab", to: "test#gitlab"
    post "test/github", to: "test#github"

    get  "commit_events/:id/delete",  to: "commit_events#confirm", as: :scm_adapter_commit_event_confirm
    post "commit_events/:id/delete", to: "commit_events#destroy", as: :scm_adapter_commit_event_delete

    # Projekt-spezifische Einstellungen (Clone-Base-URL etc.)
    scope "/projects/:project_id" do
      get  "settings", to: "scm_adapter/project_settings#edit",   as: :project_scm_adapter_settings
      put  "settings", to: "scm_adapter/project_settings#update"
      post "settings", to: "scm_adapter/project_settings#update"
    end

    # Webhooks ohne doppelten Pfad-Prefix (/scm_adapter/webhooks/*)
    namespace :webhooks, module: "webhooks" do
      post "gitlab", to: "gitlab#create"
      post "github", to: "github#create"
    end

    post "comment_back", to: "comment_backs#create", as: :scm_adapter_comment_back
    post "comment_back/preview", to: "comment_backs#preview", as: :scm_adapter_comment_back_preview
  end
end
