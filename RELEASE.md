# Release-Checkliste

## Vorbereitung
- Version erhoehen in `lib/scm_adapter/version.rb` und `scm_adapter.gemspec`; Changelog/ADR aktualisieren.
- Dependencies fixieren: `bundle lock --add-platform x86_64-linux` auf Build-Host ausfuehren und `Gemfile.lock` einchecken.
- Tests laufen lassen: `bundle exec rake redmine:plugins:test NAME=scm_adapter RAILS_ENV=test` (Test-DB/Config noetig).
- Optional: Lint/Format (falls konfiguriert), z.B. `bundle exec rubocop`.

## Packaging (Tarball bevorzugt)
- Tarball bauen (nur noetige Files):
  ```sh
  tar czf scm_adapter-${VERSION}.tar.gz \
    app config db lib doc Gemfile Gemfile.lock Rakefile init.rb scm_adapter.gemspec config.ru LICENSE README.md INSTALL.md DOCKER_INSTALL.md
  ```
- Upload als Release-Asset auf GitHub/GitLab statt Force-Push (z.B. per CI).
- Falls als Gem verteilen: `gem build scm_adapter.gemspec` (nicht zwingend fuer Redmine-Plugin-Deploy).

## Deploy-Schritte (klassisch)
1) Plugin nach `REDMINE_ROOT/plugins/scm_adapter` legen.
2) `bundle install --without development test` im Redmine-Root.
3) Migrationen: `bundle exec rake redmine:plugins:migrate NAME=scm_adapter RAILS_ENV=production`.
4) Redmine neu starten; Sidekiq-Prozess mit gleicher Codebasis/ENV starten.

## Deploy-Schritte (docker-compose)
- Image neu bauen und Stack hochfahren:
  ```sh
  docker compose -f infrastruktur/docker-compose.redmine.yml build
  docker compose -f infrastruktur/docker-compose.redmine.yml up -d
  ```
- Migrationslauf erfolgt im App-Container-Entrypoint; Sidekiq laeuft als eigener Service.

## Nach dem Deploy
- Plugin-Settings setzen: Basis-URLs, Tokens und **Webhook-Secrets (verpflichtend, sonst 401)**.
- Webhooks im SCM testen (GitLab/GitHub) mit korrekten Signaturen/Tokens.
- Logs pruefen (Redmine/Sidekiq) auf Fehler bei Projekt-Mapping oder Auth.
