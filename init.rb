# frozen_string_literal: true

require "redmine"
require_relative "lib/scm_adapter/engine"
require_relative "lib/scm_adapter/version"
require_relative "lib/scm_adapter/instrumentation"
require_relative "lib/scm_adapter/author_resolver"
require_relative "lib/scm_adapter/hooks/issue_hooks"
require_relative "lib/scm_adapter/hooks/layout_hooks"
require_relative "lib/scm_adapter/patches/repositories_helper_patch"
require_relative "lib/scm_adapter/patches/diff_patch"
require_relative "lib/scm_adapter/hooks/revision_hooks"

Redmine::Plugin.register :scm_adapter do
  name        "SCM Adapter"
  author      "Atilla Sen"
  description "Integration von GitLab & GitHub inkl. Sync, Webhooks, Sidekiq-Jobs."
  version     ScmAdapter::VERSION
  url         "https://example.com/scm_adapter"
  author_url  "https://example.com"

  requires_redmine version_or_higher: "5.0.0"

  settings default: {
    "gitlab_base_url" => "",
    "gitlab_clone_base_url" => "",
    "gitlab_token" => "",
    "gitlab_webhook_secret" => "",
    "github_base_url" => "https://api.github.com",
    "github_clone_base_url" => "https://github.com",
    "github_token" => "",
    "github_webhook_secret" => "",
    "issue_status_mapping" => {
      "opened" => "New",
      "in_progress" => "In Progress",
      "closed" => "Closed",
      "merged" => "Resolved"
    },
    "close_keywords" => %w[fixes closes resolves],
    "sidekiq_enabled" => true,
    "mirror_base_path" => "/usr/src/redmine/git-mirrors",
    "git_binary" => "git",
    "comment_back_enabled" => true,
    "issue_commits_position" => "bottom",
    "author_aliases" => {},
    # Webhook-Mode kann pro Provider gesetzt werden; fallback auf webhook_mode fuer Abwaertskompatibilitaet.
    "webhook_mode" => "both", # both | plugin_only | core_only (legacy/global)
    "gitlab_webhook_mode" => "both",
    "github_webhook_mode" => "both"
  }, partial: "settings/scm_adapter_settings"

  menu :project_menu,
       :scm_adapter_settings,
       { controller: "scm_adapter/project_settings", action: :edit },
       caption: "SCM Adapter",
       param: :project_id
end
