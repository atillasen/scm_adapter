# frozen_string_literal: true

module ScmAdapter
  module Sync
    class CloseKeywordParser
      def initialize(allowed_keywords:)
        @allowed = Array(allowed_keywords).map { |kw| kw.to_s.downcase }.uniq
        @regex   = build_regex(@allowed)
      end

      def extract_issue_ids(text)
        return { ids: [], close_keyword: false } if text.to_s.empty?

        ids = []
        close_keyword = false

        if @regex
          ids += text.scan(@regex).flat_map do |keyword, issues|
            next [] unless @allowed.include?(keyword.downcase)
            close_keyword = true
            issues.scan(/\#(\d+)/).flatten.map(&:to_i)
          end
        end

        # Fallback: alle #<zahl>-Referenzen
        ids += text.scan(/\#(\d+)/).flatten.map(&:to_i)

        { ids: ids.uniq, close_keyword: close_keyword }
      end

      private

      def build_regex(keywords)
        return nil if keywords.empty?
        pattern = Regexp.union(keywords.map { |kw| Regexp.escape(kw) })
        /\b(?<keyword>#{pattern})\b\s+(?<issues>(?:\#\d+[,\s]*)+)/i
      end
    end
  end
end
