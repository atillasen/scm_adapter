# Test-Doku – SCM Adapter

## Ziel
Leitfaden fuer das Ausfuehren der Plugin-Tests (Unit/Integration) lokal oder im Docker-Stack.

## Voraussetzungen
- Redmine 6.0 (Rails 7.2, Ruby 3.3)
- Test-Datenbank konfiguriert (`config/database.yml` mit `test:` Abschnitt, z.B. MySQL oder PostgreSQL)
- Bundler-Abhaengigkeiten installiert (Test-Gruppe nicht ausgeschlossen)

## Tests ausfuehren (klassisch)
1) Im Redmine-Root:
   ```sh
   bundle install
   bundle exec rake redmine:plugins:test NAME=scm_adapter RAILS_ENV=test
   ```
2) Sicherstellen, dass `config/database.yml` die Test-DB enthaelt (Beispiel MySQL):
   ```yaml
   test:
     adapter: mysql2
     database: redmine_test
     host: localhost
     username: redmine
     password: redminepass
     encoding: utf8mb4
   ```

## Tests im Docker-Stack
- Container muss Test-DB-Config besitzen (z.B. per bind mount von `config/database.yml`).
- Kommando im Redmine-Container:
  ```sh
  docker compose -f infrastruktur/docker-compose.redmine.yml exec redmine \
    bundle exec rake redmine:plugins:test NAME=scm_adapter RAILS_ENV=test
  ```
- Logs/Ergebnisse im Container-Output; bei DB-Fehlern DB-User/Passwort pruefen.

## Was wird abgedeckt
- Unit-Tests: Clients (GitHub/GitLab), Close-Keyword-Parser.
- Integration-Tests: Webhooks (GitHub/GitLab).

## Hinweise
- MySQL: JSON-Felder ohne Default; Code muss Nil abfangen (siehe ADR 0001).
- PostgreSQL: jsonb mit Default, abweichende Typen moeglich.
- Sidekiq: Tests laufen ohne echten Sidekiq-Prozess (ActiveJob Inline/Adapter im Test).
- Port-Konflikte vermeiden, wenn parallel ein laufender Stack die Test-DB blockiert.

## Troubleshooting Tests
- `Access denied` / DB-Fehler: DB-Credentials/Host in `config/database.yml` korrigieren; DB-User/Schema anlegen.
- Fehlende Gems: `bundle install` ohne Ausschluss der Test-Gruppe ausfuehren.
- HMAC/Token-Checks in Integrationstests schlagen fehl: Test-Fixtures/Secrets pruefen (Header gesetzt?).
