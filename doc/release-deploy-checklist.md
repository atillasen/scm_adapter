# Release- / Deploy-Checkliste – SCM Adapter

## Vorbereiten (Release)
- Version bump in `lib/scm_adapter/version.rb` und `scm_adapter.gemspec`.
- `Gemfile.lock` aktualisieren (Build-Host, Plattform fixieren falls noetig).
- Changelog/ADRs aktualisieren (neue Entscheidungen festhalten).
- Tests ausfuehren:
  ```sh
  bundle exec rake redmine:plugins:test NAME=scm_adapter RAILS_ENV=test
  ```
- Optional: Lint/Format (falls konfiguriert).

## Paketieren
- Tarball (empfohlen fuer Redmine-Plugin):
  ```sh
  tar czf scm_adapter-${VERSION}.tar.gz \
    app config db lib doc Gemfile Gemfile.lock Rakefile init.rb scm_adapter.gemspec config.ru LICENSE README.md INSTALL.md DOCKER_INSTALL.md
  ```
- Alternativ: `gem build scm_adapter.gemspec` (nicht zwingend fuer Redmine-Deploy).

## Deploy (klassisch)
1) Plugin nach `REDMINE_ROOT/plugins/scm_adapter` legen.
2) Im Redmine-Root:
   ```sh
   bundle install --without development test
   bundle exec rake redmine:plugins:migrate NAME=scm_adapter RAILS_ENV=production
   ```
3) Redmine neu starten; Sidekiq mit gleicher Codebasis/ENV starten.
4) Nach Deploy: Plugin-Settings pruefen; Webhook-Test ausloesen; Logs checken.

## Deploy (docker-compose)
1) Build/Start:
   ```sh
   docker compose -f infrastruktur/docker-compose.redmine.yml build
   docker compose -f infrastruktur/docker-compose.redmine.yml up -d
   ```
   (Migrationen laufen im Entrypoint)
2) Healthcheck: `docker compose -f infrastruktur/docker-compose.redmine.yml ps`
3) Logs: `... logs -f redmine` / `... logs -f sidekiq`
4) Nach Deploy: Plugin-Settings pruefen; Webhook-Test ausloesen; Logs checken.

## Nacharbeiten
- Webhooks im SCM testen (GitLab/GitHub); auf 200/OK und korrekte Signatur/Token achten.
- Fehlermetriken/Alerts beobachten (Webhook-Fehler, Job-Retries).
- Dokumentation aktualisieren (Wiki/Guides), falls sich Einstellungen oder Flows geaendert haben.

## Rollback (kurz)
- Bei klassischem Deploy: altes Plugin-Backup einspielen, Migrationen ggf. zurueckrollen:
  ```sh
  bundle exec rake redmine:plugins:migrate NAME=scm_adapter VERSION=<prev> RAILS_ENV=production
  ```
- Bei docker-compose: Vorheriges Image/Tag neu starten; Volumes/DB unveraendert lassen.***
