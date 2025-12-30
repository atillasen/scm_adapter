# Betriebshandbuch – SCM Adapter

## Zweck
- Betrieb und Fehlerbehebung fuer den SCM Adapter (GitLab/GitHub) in Redmine.

## Umgebung
- Redmine 6.0 (Rails 7.2, Ruby 3.3)
- docker-compose: Services `db` (MySQL 8), `redis`, `redmine` (Puma), `sidekiq`
- Plugin-Pfad: `redmine/plugins/scm_adapter`

## Start/Stop/Restart (Docker)
- Start: `docker compose -f infrastruktur/docker-compose.redmine.yml up -d --build`
- Stop: `docker compose -f infrastruktur/docker-compose.redmine.yml down`
- Restart einzelner Services: `docker compose -f infrastruktur/docker-compose.redmine.yml restart redmine sidekiq`

## Health/Status
- Dienste: `docker compose -f infrastruktur/docker-compose.redmine.yml ps`
- Logs:
  - Redmine: `docker compose -f infrastruktur/docker-compose.redmine.yml logs -f redmine`
  - Sidekiq: `docker compose -f infrastruktur/docker-compose.redmine.yml logs -f sidekiq`
  - DB/Redis bei Bedarf analog.
- Mirror-Check: `bundle exec rake scm_adapter:mirror:health` (zeigt fehlende Mirror/Repo-Pfade; mit `FIX=1` wird synchronisiert und Pfade gesetzt). In Docker: `docker compose -f infrastruktur/docker-compose.redmine.yml exec redmine bundle exec rake scm_adapter:mirror:health FIX=1`.
- Backfill (historische Commits ohne Limit, Close-Keywords werden ausgewertet, keine Remote-Kommentare):  
  `bundle exec rake scm_adapter:backfill:commits PROJECT=<identifier>` (optional PROJECT-Filter, `SKIP_SYNC=1` falls Mirror bereits lokal vorliegt). In Docker:  
  `docker compose -f infrastruktur/docker-compose.redmine.yml exec redmine bundle exec rake scm_adapter:backfill:commits PROJECT=<identifier> SKIP_SYNC=1`

## Konfiguration
- Redmine: Administration → Plugins → SCM Adapter → Konfigurieren
- Pflicht: Base-URL, Token, Webhook-Secret pro Provider (GitHub HMAC, GitLab Token)
- Webhook-Modus pro Provider waehlen: `both` (Plugin + Core), `plugin_only` (nur /scm_adapter/webhooks), `core_only` (nur /sys/fetch_changesets; blockiert Plugin-Webhooks des Providers).
- Optional: Mirror-Pfad, Git-Binary, Kommentar-Back, Position der Commits im Ticket
- Mirror-Sync beim Anlegen/Ändern von ProjectLinks: Beim Speichern wird der Mirror sofort synchronisiert und das Projekt-Repository auf den Mirror-Pfad gesetzt (fail-fast). Spiegel-Pfad muss auf den Container-Pfad zeigen (z.B. `/usr/src/redmine/git-mirrors`).

## Webhooks
- GitLab: `POST /scm_adapter/webhooks/gitlab`, Header `X-Gitlab-Token`
- GitHub: `POST /scm_adapter/webhooks/github`, Header `X-Hub-Signature-256` (HMAC-SHA256)
- Events: Push, Merge/Pull Request
- Projektaufloesung: erst `remote_project_id`, dann `remote_full_path`; 409 bei Mehrfachtreffer, 404 bei fehlendem Mapping.

## Daten/Modelle
- ProjectLinks: Zuordnung Redmine-Projekt ↔ Repo-ID/Pfad je Provider
- IntegrationSettings: Base-URL, Token, Webhook-Secret, Optionen
- SyncRules: Status-/Keyword-Mappings (JSON)
- CommitEvents: Commits/Soft-Delete mit Journal-Note

## Jobs/Queues
- Sidekiq empfohlen; Fallback: Inline (hoeherer Latenzpfad)
- Typische Queues: Webhook-Dispatch, Mirror-Sync, Kommentar-Back
- Check: Sidekiq-Logs, ggf. Sidekiq-UI falls angebunden

## Troubleshooting (kurz)
- 401 Webhooks: Secret fehlt/abweichend; Header pruefen (GitHub HMAC, GitLab Token); Secret im Plugin setzen.
- 404 Webhooks: Kein ProjectLink; Mapping via Repo-ID oder Pfad anlegen.
- 409 Webhooks: Mehrere ProjectLinks fuer dasselbe Repo/Pfad; Duplikate bereinigen.
- 5xx/Timeout: Provider-API down oder Token ungueltig; API erreichbar? Token erneuern.
- Jobs bleiben liegen: Redis/Sidekiq down? `docker compose ... logs -f sidekiq` pruefen; Redis erreichbar?
- Mirror-Sync blockiert/404 im Repository-Tab: Mirror-Check laufen lassen (`rake scm_adapter:mirror:health`), ggf. `FIX=1` nutzen; CA/SSL-Setting pruefen (`SCM_ADAPTER_CA_FILE`, `SCM_ADAPTER_SSL_VERIFY`).

## Wartung/Deploy
- Klassisch: `bundle install --without development test` im Redmine-Root, dann `bundle exec rake redmine:plugins:migrate NAME=scm_adapter RAILS_ENV=production`, Redmine/Sidekiq neu starten.
- Docker: `docker compose -f infrastruktur/docker-compose.redmine.yml build && docker compose -f infrastruktur/docker-compose.redmine.yml up -d` (Migrationen laufen im Entrypoint).
- Nach Deploy: Settings pruefen, Webhook-Test ausloesen, Logs checken.

## Monitoring (Kurzempfehlung)
- Metriken/Alerts: Webhook-Fehlerquote (401/404/409/5xx), Job-Retries/Failures, Latenz (Webhook P95), Redis/DB-Health.
- Falls Sidekiq-UI oder externes Monitoring vorhanden, dort Schwellenwerte pflegen.

## Sicherheit
- Admin-UI schuetzen (Zugriff nur fuer Admins).
- Secrets/Tokens liegen im Klartext in Settings; Zugriff beschraenken.
- CSRF fuer Webhooks aus; Schutz ueber Secret/Token.

## Nichtziele (Scope)
- Kein Repo-Provisioning oder Rechte-Management im SCM.
- Keine Diff-/Volltextanzeige, nur Metadaten-Liste in Tickets.
- Sidekiq-UI nicht Teil des Plugins (optional anbinden).
