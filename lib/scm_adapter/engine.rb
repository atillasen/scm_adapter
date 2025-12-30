# frozen_string_literal: true
module ScmAdapter
  class Engine < ::Rails::Engine
    engine_name :scm_adapter
    initializer "scm_adapter.helpers" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Base.include ScmAdapter::BreadcrumbsHelper
        ActionView::Base.include ScmAdapter::CommentBackHelper
      end
      ActiveSupport.on_load(:action_controller) do
        ActionController::Base.helper ScmAdapter::CommentBackHelper
      end
    end

    initializer "scm_adapter.active_job" do
      # NOP – Einstellung via config/initializers/active_job.rb
    end

    initializer "scm_adapter.unloadable_compat" do
      # Redmine 6/ Rails 7 nutzt Zeitwerk; ältere Plugins rufen manchmal noch `unloadable`
      unless ApplicationController.respond_to?(:unloadable)
        ApplicationController.singleton_class.define_method(:unloadable) {}
      end
    end

    initializer "scm_adapter.ensure_admin_group" do
      # Legt bei Bedarf die Gruppe "SCM Adapter Admin" an, falls sie noch nicht existiert.
      begin
        if defined?(Group) && Group.table_exists?
          Group.find_or_create_by!(lastname: "SCM Adapter Admin") do |group|
            group.mail_notification = false
          end
        end
      rescue StandardError => e
        Rails.logger.warn("[scm_adapter] Gruppe konnte nicht angelegt werden: #{e.class}: #{e.message}") if defined?(Rails)
      end
    end
  end
end
