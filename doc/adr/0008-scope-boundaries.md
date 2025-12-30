# ADR 0008: Scope-Grenzen und Nichtziele

## Kontext
- Erwartungsmanagement fuer den SCM Adapter ist wichtig, damit Feature-Wuensche und Betriebsaufwand klar abgegrenzt sind.
- Es gibt ausdrueckliche Nichtziele (z.B. Repo-Provisioning, Diff-Anzeige) und spaetere Ausbaustufen (weitere Provider).

## Entscheidung
- Nichtziele:
  - Kein Repo-Provisioning oder Rechte-Management im SCM (Adapter konsumiert nur Events/APIs vorhandener Repos).
  - Keine Diff-/Volltextanzeige von Commits, nur Metadaten-Liste im Ticket.
  - Kein Sidekiq-Web-UI im Kern-Plugin; kann separat angebunden werden.
- Provider-Scope:
  - Aktuell nur GitHub/GitLab; weitere Provider sind explizit Spaeter-Scope und erfordern eigenen ADR/Backlog-Eintrag (siehe ADR 0005).
- Webhook-Security und Fehlercodes bleiben Bestandteil des Kerns (401/404/409), keine IP-Whitelist oder Rate-Limiting im Plugin selbst.

## Konsequenzen
- Feature-Anfragen ausserhalb des Scopes muessen separat bewertet und eingeplant werden.
- Betrieb kann sich auf die definierten Schnittstellen/Webhooks konzentrieren; keine Erwartungen an SCM-Verwaltung im Adapter.
- Erweiterungen um neue Provider folgen dem in ADR 0005 beschriebenen Muster.

## Status
- Akzeptiert
