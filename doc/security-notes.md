# Security-Hinweise – SCM Adapter

## Webhook-Schutz
- Secrets sind Pflicht: GitHub HMAC-SHA256 (`X-Hub-Signature-256`), GitLab Token (`X-Gitlab-Token`); fehlend/falsch -> 401.
- CSRF fuer Webhooks ist deaktiviert; Schutz erfolgt ueber Secret/Token.
- Konflikte und fehlende Mappings liefern 409/404, verhindern falsche Zuordnung.

## Token/Secrets
- Tokens und Webhook-Secrets liegen im Klartext in den Plugin-Settings (Redmine-DB); Admin-Zugriff auf die Settings streng beschraenken.
- Starke Secrets waehlen; regelmaessig rotieren; nach Rotation im SCM und im Plugin gleichsetzen.

## Zugriff/Administration
- Nur Administratoren sollten die Plugin-Settings aendern duerfen.
- Redmine-Instanz absichern (TLS, Admin-Accounts, Rollen/Rechte).

## Netzwerk/Exposure
- Webhook-Endpunkte nur ueber vertrauenswuerdige Pfade zugaenglich machen (idealerweise hinter WAF/Reverse Proxy mit Rate-Limits/IP-Filter).
- Keine zusaetzlichen IP-Whitelists oder Rate-Limits im Plugin selbst; muss vorgelagert erfolgen.

## Logging/Monitoring
- Logs enthalten Provider, Event-Typ und Projekt-IDs; keine Secrets im Log ausgeben.
- Monitoring/Alerts fuer Webhook-Fehler (401/404/409/5xx) und Job-Retries aktivieren (siehe Monitoring-Guide).

## Scope/Nichtziele
- Kein Repo-Provisioning oder Rechte-Management im SCM.
- Keine Diff-/Volltextanzeige von Commits, nur Metadaten.
- Sidekiq-UI nicht Teil des Plugins (optional separat absichern, falls aktiviert).
