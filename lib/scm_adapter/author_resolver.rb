# frozen_string_literal: true

module ScmAdapter
  module AuthorResolver
    module_function

    def resolve(name)
      return name if name.to_s.empty?

      mapping = Setting.plugin_scm_adapter.to_h["author_aliases"]
      mapping = mapping.is_a?(Hash) ? mapping : {}
      mapping[name.to_s].presence || name
    rescue StandardError
      name
    end
  end
end
