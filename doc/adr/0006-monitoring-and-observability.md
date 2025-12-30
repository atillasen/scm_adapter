# ADR 0006: Monitoring & Observability

## Kontext
- Bisher nur Basis-Logging ueber Rails/Sidekiq/Container-Logs; keine definierten Metriken oder Alerts.
- Webhooks koennen durch fehlende Secrets/Mapping oder SCM-Ausfaelle scheitern; Background-Jobs koennen in Retries laufen.

## Entscheidung
- Kern-Metriken definieren und erfassen (z.B. via Sidekiq-Stats/Logs oder externes Monitoring):
  - Webhook-Erfolg/Fehler nach Provider und HTTP-Status (insb. 401/404/409/5xx).
  - Job-Erfolge/Retries/Failures pro Queue.
  - Latenz: P95 Webhook-Gesamtzeit (Empfang bis Dispatch), P95 Job-Laufzeit.
  - Infrastruktur: Redis/DB-Availability (Ping/Latenz) als Betriebsmetriken.
- Alerts ableiten (z.B. Fehlerquote Webhooks, steigende Retries, Redis down).
- Sidekiq-UI oder externe Ueberwachung optional anbinden; nicht Bestandteil des Kern-Plugins, aber empfohlen.
- Log-Formate beibehalten, aber Fehlerpfade eindeutig kennzeichnen (Provider, Event-Typ, Projekt-IDs).

## Konsequenzen
- Zusätzliche Betriebsaufgaben: Metrik-Quelle waehlen (Sidekiq-UI, externe APM/Logs), Schwellenwerte pflegen.
- Keine harte Abhaengigkeit im Plugin; ohne Monitoring laeuft der Adapter weiter, aber Operability leidet.
- Klare IDs/Provider im Log erleichtern Support und Fehlersuche.

## Status
- Akzeptiert
