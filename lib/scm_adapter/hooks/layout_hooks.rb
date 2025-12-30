# frozen_string_literal: true

module ScmAdapter
  module Hooks
    class LayoutHooks < Redmine::Hook::ViewListener
      # Injects plugin stylesheet globally so repository breadcrumbs get the compact layout.
      def view_layouts_base_html_head(_context = {})
        stylesheet_link_tag("scm_adapter", plugin: "scm_adapter")
      end
    end
  end
end
