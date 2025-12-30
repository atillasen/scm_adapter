# frozen_string_literal: true

require "json"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/object/blank"

module ScmAdapter
  module Sync
    class Mapping
      # Beispiel-Mapping: SCM-Status -> Redmine-Issue-Status
      DEFAULT = {
        "opened"      => "New",
        "in_progress" => "In Progress",
        "merged"      => "Resolved",
        "closed"      => "Closed"
      }.freeze

      DEFAULT_CLOSE_KEYWORDS = %w[fixes closes resolves].freeze

      def initialize(project:)
        @project = project
      end

      def issue_status_map
        rules = sync_rule&.issue_status_mapping.presence
        mapping = rules || plugin_issue_status_mapping || DEFAULT
        mapping.with_indifferent_access
      end

      def close_keywords
        rules = sync_rule&.close_keywords.presence
        keywords = rules || plugin_close_keywords || DEFAULT_CLOSE_KEYWORDS
        normalize_close_keywords(keywords)
      end

      # Auflösung eines Redmine-Issue-Status-Namens zur ID
      def redmine_status_id_by_name(name)
        status = IssueStatus.find_by(name: name)
        status&.id
      end

      private

      def sync_rule
        @sync_rule ||= ScmAdapter::SyncRule.find_by(project_id: @project.id)
      end

      def plugin_issue_status_mapping
        parsed = parse_json(settings["issue_status_mapping"])
        parsed.is_a?(Hash) ? parsed : nil
      end

      def plugin_close_keywords
        parsed = parse_json(settings["close_keywords"])
        parsed.is_a?(Array) ? parsed : nil
      end

      def settings
        @settings ||= Setting.plugin_scm_adapter.to_h
      end

      def parse_json(raw)
        case raw
        when String
          JSON.parse(raw)
        when Hash, Array
          raw
        else
          nil
        end
      rescue JSON::ParserError
        nil
      end

      def normalize_close_keywords(list)
        Array(list).map { |kw| kw.to_s.downcase }.reject(&:empty?).presence || DEFAULT_CLOSE_KEYWORDS
      end
    end
  end
end
