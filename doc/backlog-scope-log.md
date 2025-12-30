# Backlog / Scope-Log – SCM Adapter

## Aktueller Scope
- Provider: GitHub, GitLab.
- Funktionen: Webhooks (Push, MR/PR), Close-Keyword-Sync, Commit-Liste im Ticket (Metadaten, Soft-Delete mit Journal), optional Kommentar-Back, Mirror-Unterstuetzung.
- Webhook-Sicherheit: Pflicht-Secrets/Tokens, Fehlercodes 401/404/409, keine IP-Whitelists/Rate-Limits im Plugin.
- Queues: Sidekiq/Redis empfohlen, Inline-Fallback.

## Nichtziele (explizit ausgeschlossen)
- Repo-Provisioning oder Rechte-Management im SCM.
- Diff-/Volltextanzeige von Commits.
- Sidekiq-Web-UI im Kern-Plugin (kann separat angebunden werden).

## Spaeterer Scope / Kandidaten
- Weitere Provider (z.B. Bitbucket) nach Muster ADR 0005.
- Rate-Limiting/IP-Filter auf Webhook-Ebene (via Proxy/WAF oder Erweiterung).
- Erweiterte Monitoring-Integration (Dashboards, Alerts) inkl. Sidekiq-UI/Stats.
- Bessere Admin-UX fuer ProjectLink-Pflege (UI/Bulk-Tools).
- Verbesserte Retry/Backoff-Konfiguration pro Queue/Provider.
- Mirror-Optimierungen (separate Queue-Settings, Progress/Status-Anzeige).
- Ticket-Commit-Panel: optionaler History-Graph (wie Revisionsseite) inkl. Branch/Elternpfade.
- Monitoring-Ausbau: Queue-Wartezeit/Retry-Zähler messen (P95 Enqueue->Start, Retry-Anzahl) gemäß ADR 0007 ergänzen.

## Status/Referenzen
- Provider-Erweiterbarkeit: ADR 0005.
- Monitoring: ADR 0006; Performanceziele: ADR 0007.
- Scope-Grenzen/Nichtziele: ADR 0008.
