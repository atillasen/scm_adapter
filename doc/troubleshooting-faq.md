# Troubleshooting-FAQ – SCM Adapter

## Webhooks
- **401 Unauthorized**  
  Ursache: Secret fehlt/abweicht; Header nicht gesetzt (GitHub `X-Hub-Signature-256`, GitLab `X-Gitlab-Token`).  
  Fix: Secret in den Plugin-Settings setzen und identisch im SCM hinterlegen; Test-Event schicken.
- **403 Plugin-Webhooks deaktiviert**  
  Ursache: Webhook-Modus steht auf `core_only`.  
  Fix: In den Plugin-Settings Webhook-Modus auf `both` oder `plugin_only` stellen.
- **404 Project not found**  
  Ursache: Kein ProjectLink fuer Repo-ID/Pfad.  
  Fix: ProjectLink anlegen (`provider`, `remote_project_id`, `remote_full_path`, `project_id`). Lookup: erst ID, dann Pfad.
- **409 Conflict**  
  Ursache: Mehrere ProjectLinks matchen (ID/Pfad doppelt).  
  Fix: Duplikate entfernen/zusammenfassen; eindeutige Zuordnung herstellen.
- **5xx/Timeout**  
  Ursache: SCM-API down oder Token ungueltig.  
  Fix: SCM-Status pruefen, Token erneuern, Logs ansehen.

## Jobs/Queues
- **Jobs bleiben liegen / hohe Queue-Latenz**  
  Ursache: Sidekiq/Redis down oder ueberlastet; Inline-Fallback aktiv.  
  Fix: `docker compose ... ps`/`logs -f sidekiq` pruefen; Redis erreichbar? Sidekiq starten; ggf. Mirror-Jobs in eigene Queue.
- **Viele Retries/Failures**  
  Ursache: Provider-API-Fehler, Ratenlimits, falsche Tokens.  
  Fix: Retry-Logs ansehen, Token/Limits pruefen; Backoff/Max-Retries justieren.

## Mirror
- **Repo 404 in Redmine**  
  Ursache: Standard-Repo zeigt auf das falsche Remote; Mirror nicht als Standard gesetzt.  
  Fix: Mirror-Repo als Standard setzen (Projekt → Repositories) oder `mirror_base_path`/Link prüfen.
- **Mirror blockiert Webhooks**  
  Ursache: Mirror-Jobs in derselben Queue, langlaufend.  
  Fix: Mirror in eigene Queue verschieben; Sidekiq-Config pruefen.
- **Keine Schreibrechte im Mirror-Pfad**  
  Fix: Dateirechte fuer Redmine-/Sidekiq-User setzen; Pfad in Settings pruefen.

## Konfiguration
- **Verbindungstest scheitert**  
  Ursache: Base-URL/Tokens falsch, Netz- oder TLS-Problem.  
  Fix: URL/Token pruefen, Zertifikate/Proxy checken.
- **Falsche Commit-Liste/Leere Anzeige**  
  Ursachen: Kein Mapping, Close-Keywords fehlen, Events nicht angekommen, Commit wurde ausgeblendet.  
  Fix: ProjectLink pruefen, Webhook-Logs checken, Close-Keyword-Parser-Test; ggf. Soft-Delete-Rücknahme im DB-Backup.
- **Commit-Löschung ohne Begründung blockt**  
  Ursache: Begründung Pflichtfeld.  
  Fix: Reason ausfüllen; Journal-Eintrag bestätigt die Löschung.

## Diagnose-Kommandos (Docker)
- Dienste: `docker compose -f infrastruktur/docker-compose.redmine.yml ps`
- Logs:  
  - Redmine: `docker compose -f infrastruktur/docker-compose.redmine.yml logs -f redmine`  
  - Sidekiq: `docker compose -f infrastruktur/docker-compose.redmine.yml logs -f sidekiq`
- Webhook-Test im SCM ausloesen und Logs beobachten.
