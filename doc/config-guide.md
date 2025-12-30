# Konfigurations-Guide – SCM Adapter

## Ziel
Schritt-fuer-Schritt-Anleitung zur Einrichtung des SCM Adapter (GitLab/GitHub) in Redmine.

## Voraussetzungen
- Redmine 6.0 mit installiertem Plugin `scm_adapter`
- Token/Personal Access Token je Provider
- Webhook-Secret je Provider (Pflicht, sonst 401)
- Optional: Mirror-Verzeichnis und Git-Binary-Pfad, falls Mirror genutzt wird

## Plugin-Settings (Redmine UI)
1) Administration → Plugins → SCM Adapter → Konfigurieren.
2) Pro Provider (GitLab/GitHub):
   - Base URL: z.B. `https://gitlab.example.com` oder `https://api.github.com`.
   - Token/Personal Access Token eintragen.
   - Webhook-Secret setzen (muss mit SCM-Webhooks uebereinstimmen).
3) Optionen nach Bedarf:
   - Webhook-Modus pro Provider: `both` (Standard) / `plugin_only` (/scm_adapter/webhooks/...) / `core_only` (/sys/fetch_changesets); globaler Wert dient nur als Fallback fuer Alt-Konfigs.
   - Mirror-Basis-Pfad (falls Mirror genutzt wird).
   - Git-Binary-Pfad (falls nicht im PATH).
   - Kommentar-Back aktivieren/deaktivieren.
   - Position der Commits in der Ticketansicht (oben/unten).
4) Speichern.

## Webhooks im SCM
- Endpunkte:
  - GitLab: `POST /scm_adapter/webhooks/gitlab`, Header `X-Gitlab-Token: <Secret>`.
  - GitHub: `POST /scm_adapter/webhooks/github`, Header `X-Hub-Signature-256` (HMAC-SHA256 mit Secret).
- Events aktivieren:
  - GitLab: Push + Merge Request.
  - GitHub: Push + Pull Request.
- Secret im SCM identisch zum Plugin-Setting eintragen.
- Test-Event ausloesen und Logs pruefen (Redmine/Sidekiq).

## Projekt-Mapping (ProjectLink)
- Zuordnung Redmine-Projekt ↔ SCM-Repo:
  - Felder: `provider` (`gitlab`/`github`), `remote_project_id` (Repo-ID), `remote_full_path` (z.B. `group/project` bzw. `owner/repo`), `project_id` (Redmine).
  - Lookup-Reihenfolge: erst `remote_project_id`, dann `remote_full_path`.
  - Mehrfache Treffer -> 409, fehlendes Mapping -> 404.
- Anlage per Konsole oder (falls vorhanden) UI/Seed.

## Tests/Verbindung
- UI-Buttons „Verbindung testen“ je Provider nutzen (falls vorhanden).
- Webhook-Test vom SCM senden und in Logs auf 200/OK pruefen.
- Fehlerbilder:
  - 401: Secret fehlt/abweichend.
  - 404: Kein ProjectLink.
  - 409: Mehrdeutiger ProjectLink.

## Mirror (optional)
- Mirror-Basis-Pfad in den Settings setzen.
- Sicherstellen, dass der Redmine-User Schreibrechte auf den Pfad hat.
- Mirror-Sync-Job laeuft ueber Sidekiq; separate Queue empfohlen.

## Sidekiq/Jobs
- Sidekiq-Adapter verwenden; `REDIS_URL` setzen.
- Ohne Sidekiq laufen Jobs inline (hoeherer Latenzpfad).

## Sicherheit
- Admin-Zugriff auf Plugin-Settings beschraenken.
- Secrets/Tokens liegen im Klartext in Settings; Zugriffsschutz beachten.
- CSRF fuer Webhooks deaktiviert, Schutz ueber Secret/Token.
