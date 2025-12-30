# frozen_string_literal: true
namespace :scm_adapter do
  desc "Starte eine einmalige Sync-Runde für alle verknüpften Projekte"
  task sync_all: :environment do
    ScmAdapter::ProjectLink.find_each do |link|
      case link.provider
      when "gitlab"
        ScmAdapter::JobRunner.run(
          ScmAdapter::GitlabSyncJob,
          project_id: link.project_id,
          remote_project_id: link.remote_project_id
        )
      when "github"
        ScmAdapter::JobRunner.run(
          ScmAdapter::GithubSyncJob,
          project_id: link.project_id,
          full_name: link.remote_full_path
        )
      end
    end
    puts "Sync-Jobs enqueued."
  end

  namespace :mirror do
    desc "Prüft Mirror-Repos und Repository-Pfade (FIX=1 erzwingt Fetch/Sync und korrigiert die Pfade)"
    task health: :environment do
      fix = ENV["FIX"].to_s == "1" || ENV["CHECK_FIX"].to_s == "1"
      checker = ScmAdapter::Mirror::HealthCheck.new
      results = checker.check_all(fix: fix)

      results.each do |r|
        puts "[#{r[:status].upcase}] project=#{r[:project]} provider=#{r[:provider]} - #{r[:message]}"
      end

      if results.any? { |r| r[:status] == :error }
        puts "Mirror-Health: Fehler erkannt."
        exit 1 unless fix
      end
    end
  end

  namespace :backfill do
    desc "Importiert historische Commits anhand Close-Keywords (ohne Limit). PROJECT=<identifier> optional."
    task commits: :environment do
      scope = ScmAdapter::ProjectLink.includes(:project)
      if ENV["PROJECT"].present?
        scope = scope.joins(:project).where(projects: { identifier: ENV["PROJECT"] })
      end

      scope.find_each do |link|
        skip_sync = ENV["SKIP_SYNC"].to_s == "1"
        backfill = ScmAdapter::Mirror::BackfillCommits.new(link: link, skip_sync: skip_sync)
        count = backfill.run
        puts "[OK] project=#{link.project&.identifier} provider=#{link.provider} imported=#{count}"
      rescue StandardError => e
        warn "[ERR] project=#{link.project_id} provider=#{link.provider} error=#{e.message}"
        exit 1 if ENV["STRICT"].to_s == "1"
      end
    end
  end
end
