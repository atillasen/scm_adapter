# frozen_string_literal: true
# Extra Rouge aliases/lexers loaded with the SCM Adapter plugin.
# Extend as needed; keeps Redmine core untouched.

begin
  require "rouge"

  # Useful aliases for repositories:
  # - *.proto files
  Rouge::Lexers::Protobuf.aliases << "proto" unless Rouge::Lexers::Protobuf.aliases.include?("proto")

  # - *.graphql / *.gql files
  Rouge::Lexers::GraphQL.filenames |= ["*.graphql", "*.gql"]

  # - *.http scratch requests (HTTPie format)
  Rouge::Lexers::HTTP.filenames |= ["*.http", "*.rest"]
rescue LoadError
  Rails.logger.warn("[scm_adapter] Rouge not available; skipping custom lexers") if defined?(Rails)
end
