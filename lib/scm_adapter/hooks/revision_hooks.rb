# frozen_string_literal: true

module ScmAdapter
  module Hooks
    class RevisionHooks < Redmine::Hook::ViewListener
      # Fallback-Hook: Rendert das Widget am unteren Seitenende, wenn wir uns im RepositoriesController (revision/diff/show/changes) befinden.
      def view_layouts_base_body_bottom(context = {})
        controller = context[:controller]
        Rails.logger.debug("[scm_adapter] revision hook: skip (no controller)") unless controller if defined?(Rails)
        return "" unless controller.is_a?(RepositoriesController)
        return "" if controller.action_name == "revision" # revision-View rendert das Widget direkt

        project    = controller.instance_variable_get(:@project)
        repository = controller.instance_variable_get(:@repository)
        changeset  = controller.instance_variable_get(:@changeset)
        if defined?(Rails)
          Rails.logger.debug("[scm_adapter] revision hook: project=#{project&.identifier} repo=#{repository&.identifier} action=#{controller.action_name} changeset=#{changeset&.revision}")
        end
        return "" unless project && repository && changeset

        cfg = Setting.plugin_scm_adapter.to_h
        return "" unless cfg["comment_back_enabled"]
        return "" unless User.current.allowed_to?(:browse_repository, project)

        helper = controller.view_context
        helper ||= controller.helpers
        unless helper.respond_to?(:scm_adapter_remote_comments)
          helper = helper.tap { |h| h.extend(ScmAdapter::CommentBackHelper) }
        end
        comments = helper.scm_adapter_remote_comments(project: project, repository: repository, revision: changeset.revision)
        Rails.logger.info("[scm_adapter] render comment widget for #{project.identifier}##{changeset.revision}") if defined?(Rails)

        controller.render_to_string(
          partial: "scm_adapter/comment_back/widget",
          locals: {
            project: project,
            repository: repository,
            changeset: changeset,
            comments: comments
          }
        )
      rescue => e
        if defined?(Rails)
          Rails.logger.warn("[scm_adapter] comment widget render failed: #{e.class}: #{e.message}")
          Rails.logger.warn(e.backtrace.first(5).join("\n"))
        end
        ""
      end
    end
  end
end
