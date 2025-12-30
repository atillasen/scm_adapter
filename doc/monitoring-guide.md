# Monitoring-Guide – SCM Adapter

## Ziel
Operative Ueberwachung des SCM Adapter (GitLab/GitHub): Fehler frueh erkennen, Latenz und Queues im Blick behalten.

## Quellen
- Logs (Docker): `docker compose -f infrastruktur/docker-compose.redmine.yml logs -f redmine` / `... logs -f sidekiq`
- Sidekiq-UI (falls aktiviert) oder Sidekiq-Stats.
- Externe APM/Log- und Metriksysteme (empfohlen fuer produktive Umgebungen).

## Kern-Metriken (Empfehlung)
- Webhooks:
  - Erfolgs-/Fehlerrate pro Provider und HTTP-Status (insb. 401/404/409/5xx).
  - Latenz Webhook-Endpunkt (P95/P99), Zielwerte siehe ADR 0007 (Start: P95 < 2s).
- Jobs/Queues:
  - Queue-Latenz (Enqueue bis Start), P95 < 1s angestrebt.
  - Job-Laufzeit P95, Retries/Failures pro Queue.
- Infrastruktur:
  - Redis/DB Availability (Ping/Latenz), Sidekiq Prozess up.

## Alerts (Startschwellen, anpassbar)
- Webhook-5xx oder Gesamtfehlerquote > 0,1% ueber 15 Min (401/404/409 ausgenommen, da fachliche Ablehnungen).
- Queue-Latenz P95 > 5s ueber 10 Min.
- Retries/Failures > Schwellwert (z.B. >5 Retries/Min auf einer Queue).
- Redis/DB nicht erreichbar oder Sidekiq-Prozess down.

## Log-Hinweise
- 401: Secret/Token fehlt oder falsch (Plugin-Settings vs. SCM).
- 404: Kein ProjectLink; Mapping anlegen.
- 409: Mehrdeutiger ProjectLink; Duplikate bereinigen.
- 5xx/Timeout: SCM-API down oder Token ungueltig.
- Logs immer mit Provider, Event-Typ und Projekt-IDs versehen (bereits im Code, sonst ergaenzen).

## Checks (manuell)
- Dienste: `docker compose -f infrastruktur/docker-compose.redmine.yml ps`
- Sidekiq-Queues: Sidekiq-UI oder `docker compose ... logs -f sidekiq`
- Webhook-Test: Test-Event im SCM senden, Log auf 200/OK pruefen.
- Mirror-Health-Check: `bundle exec rake scm_adapter:mirror:health` (mit `FIX=1` werden fehlende Mirror gefetcht/synchronisiert und Repository-Pfade angepasst). In Docker: `docker compose -f infrastruktur/docker-compose.redmine.yml exec redmine bundle exec rake scm_adapter:mirror:health`.

## Dashboards (Vorschlag)
- Panel „Webhook Errors by Provider/Status“ (401/404/409 separat).
- Panel „Webhook Latency P95/P99“.
- Panel „Queue Latency & Retries per Queue“.
- Panel „Redis/DB Availability“.

## Notizen
- Inline-Fallback ohne Sidekiq erschwert Latenz-/Queue-Metriken; fuer Produktion Sidekiq nutzen.
- Schwellen und Ziele regelmaessig an Traffic und Betriebserfahrung anpassen (siehe ADR 0006/0007).
