# frozen_string_literal: true
module ScmAdapter
  module Hooks
    class IssueHooks < Redmine::Hook::ViewListener
      def view_issues_show_description_bottom(context = {})
        return "" unless position == "bottom"
        render_commits(context)
      end

      def view_issues_show_details_bottom(context = {})
        return "" unless position == "top"
        render_commits(context)
      end

      private

      def position
        Setting.plugin_scm_adapter.to_h["issue_commits_position"].presence || "bottom"
      end

      def render_commits(context)
        issue = context[:issue]
        return "" unless issue
        controller = context[:controller]
        controller.render_to_string(partial: "scm_adapter/commits/list", locals: { issue: issue })
      end
    end
  end
end
