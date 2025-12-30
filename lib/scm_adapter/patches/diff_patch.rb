# frozen_string_literal: true

module ScmAdapter
  module Patches
    module DiffPatch
      # Wrap diff code lines with Rouge highlighting based on file extension.
      def diff_to_html(diff, options = {}, &block)
        highlighted = nil
        if (path = diff.try(:path)).present?
          lang = Rouge::Lexer.guess_by_filename(path).tag rescue nil
          if lang
            formatter = Rouge::Formatters::HTMLInline.new(Rouge::Themes::ThankfulEyes.new)
            lexer = Rouge::Lexer.find_fancy(lang)
            highlighted = diff.map do |line|
              content = line[1..].to_s # strip diff marker for lexing
              code = formatter.format(lexer.lex(content))
              line[0] + code
            end.join
          end
        end

        return highlighted.html_safe if highlighted

        super
      end
    end
  end
end

RepositoriesHelper.prepend ScmAdapter::Patches::DiffPatch
