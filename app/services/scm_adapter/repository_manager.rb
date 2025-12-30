# frozen_string_literal: true

require "digest"
require "securerandom"

module ScmAdapter
  class RepositoryManager
    def initialize(project:, mirror_path:, identifier: nil)
      @project = project
      @mirror_path = mirror_path
      @identifier = identifier.presence
    end

    def ensure_git_repository!
      repo = existing_repo || repo_by_identifier || create_repo!
      repo.update!(url: @mirror_path) if repo.url != @mirror_path
      repo.fetch_changesets
      repo
    end

    private

    def existing_repo
      @project.repositories.detect { |r| r.type == "Repository::Git" && r.url == @mirror_path }
    end

    def repo_by_identifier
      @project.repositories.detect { |r| r.type == "Repository::Git" && r.identifier == provider_identifier }
    end

    def create_repo!
      attrs = {
        project: @project,
        url: @mirror_path,
        identifier: @identifier || safe_identifier,
        is_default: @project.repository.nil?
      }
      Repository::Git.create!(attrs)
    end

    def safe_identifier
      base = "scm-" + Digest::SHA1.hexdigest(@mirror_path)[0, 8]
      existing_ids = @project.repositories.pluck(:identifier)
      return base unless existing_ids.include?(base)
      base + "-" + SecureRandom.hex(2)
    end

    def provider_identifier
      return @identifier if @identifier.present?
      nil
    end
  end
end
