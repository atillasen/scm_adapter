# frozen_string_literal: true

class ScmAdapter::CommentBacksController < ApplicationController
  before_action :require_login
  before_action :find_project_and_repo
  before_action :authorize_repo

  def create
    body = annotate_code_blocks(params[:comment_body].to_s.strip)
    return render status: :unprocessable_entity, plain: "Kommentar darf nicht leer sein" if body.empty?

    cfg = Setting.plugin_scm_adapter.to_h
    provider = detect_provider(@repository)
    link = ScmAdapter::ProjectLink.find_by(project_id: @project.id, provider: provider)
    return render status: :not_found, plain: "Projekt-Link für #{provider} fehlt" unless link

    sha = params[:revision].to_s
    begin
      case provider
      when "gitlab"
        client = ScmAdapter::Clients::GitlabClient.new(
          base_url: cfg["gitlab_base_url"],
          token: cfg["gitlab_token"]
        )
        client.post_commit_comment(link.remote_project_id, sha, decorated_body(body))
      when "github"
        client = ScmAdapter::Clients::GithubClient.new(
          base_url: cfg["github_base_url"],
          token: cfg["github_token"]
        )
        client.post_commit_comment(link.remote_full_path, sha, decorated_body(body))
      end
      flash[:notice] = "Kommentar wurde an #{provider.titleize} gesendet."
    rescue => e
      flash[:error] = "Senden fehlgeschlagen: #{e.message}"
    end
    redirect_back fallback_location: {
      controller: "repositories",
      action: "revision",
      id: @project,
      repository_id: @repository.identifier_param,
      rev: params[:revision]
    }
  end

  # Preview renderer for Markdown/Textilizable
  def preview
    deny_access unless User.current.allowed_to?(:manage_repository, Project.find(params[:project_id]))
    body = annotate_code_blocks(params[:comment_body].to_s.gsub("'''", "```"))
    html = view_context.textilizable(body)
    render html: html
  end

  private

  def find_project_and_repo
    @project = Project.find(params[:project_id])
    @repository = @project.repositories.find(params[:repository_id])
  end

  def authorize_repo
    deny_access unless User.current.allowed_to?(:manage_repository, @project)
  end

  def detect_provider(repo)
    id = repo.identifier.to_s.downcase
    return "gitlab" if id.include?("gitlab")
    return "github" if id.include?("github")
    # Fallback: prefer gitlab
    "gitlab"
  end

  def decorated_body(body)
    user = User.current
    if user.logged?
      marker = "[redmine_user:#{user.login}]"
      "#{body}\n\n#{marker}"
    else
      body
    end
  end

  # Versucht, für Markdown-Codeblöcke ohne Sprachangabe eine Sprache zu erraten
  # und fügt sie als ```lang …``` ein, damit Syntax-Highlighting greift.
  def annotate_code_blocks(text)
    return text if text.blank?

    text.gsub(/```(\w+)?\s*\n(.*?)```/m) do
      lang = Regexp.last_match(1)
      code = Regexp.last_match(2)
      next "```#{lang}\n#{code}```" if lang.present?

      guessed = begin
        Rouge::Lexer.guess(source: code).tag
      rescue StandardError
        nil
      end
      guessed ? "```#{guessed}\n#{code}```" : "```\n#{code}```"
    end
  end
end
