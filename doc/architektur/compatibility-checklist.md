# Redmine-6-Kompatibilitaets-Checkliste

- Basis: Redmine 6.0.0 (Rails 7.2, Ruby 3.3) wird im Dockerfile geklont und gebaut.
- Datenbank: MySQL 8 im Default-Compose; Migration 003 nutzt JSON ohne Default fuer MySQL, jsonb mit Default fuer PostgreSQL.
- Bundler: Gems hinzugefuegt (sidekiq, redis, faraday, faraday-retry, multi_json, connection_pool); nur Development-Gruppe ausgeschlossen, Test-Gruppe bleibt fuer puma/Systemtest-Abhaengigkeiten.
- Entrypoint: `bundle exec rake db:migrate`, danach `bundle exec rake redmine:plugins:migrate NAME=scm_adapter`, Start via `bundle exec rails server -b 0.0.0.0`.
- Secrets/ENV: `SECRET_KEY_BASE`, `REDMINE_DB_*`, `REDIS_URL` muessen gesetzt sein (Compose tut das per Defaults/ENV).
- Zeitwerk: `unloadable`-Shim im Engine-Initializer, damit alte Aufrufe keine NameError werfen.
- Background-Jobs: Sidekiq als Adapter, Redis als Backend, eigener Container `redmine_sidekiq` mit shared Plugin-Volume.
- Webhooks: CSRF ausgeschaltet; Signatur-/Token-Pruefung ist verpflichtend (GitHub HMAC-SHA256 `X-Hub-Signature-256`, GitLab `X-Gitlab-Token`), fehlendes Secret oder fehlender/ungueltiger Header -> 401; Zuordnung der Redmine-Projekte zuerst ueber Repo-ID, dann Pfad, Konflikte -> 409, fehlendes Mapping -> 404.
- Tests (manuell im Container): `bundle exec rake redmine:plugins:test NAME=scm_adapter RAILS_ENV=test` (benoetigt Testdatenbank/Config) oder App-Stack mit `docker compose -f infrastruktur/docker-compose.redmine.yml up --build` starten und integrativ pruefen.
- Ports: App auf 3000, nach aussen 8090 (Compose).
