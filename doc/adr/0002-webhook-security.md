# ADR 0002: Webhook-Sicherheit

## Kontext
- Webhooks fuer GitHub/GitLab empfangen JSON; Secrets liegen in Settings.

## Entscheidung
- Signatur-/Token-Pruefung aktiviert und verpflichtend:
	- GitHub: HMAC-SHA256 (Header `X-Hub-Signature-256`) gegen `github_webhook_secret` mittels `secure_compare`; fehlendes Secret oder fehlende Signatur -> 401.
	- GitLab: Token-Abgleich (Header `X-Gitlab-Token`) gegen `gitlab_webhook_secret`; fehlendes Secret oder Token -> 401.
- Projektauflosung haerted: erst Repo-ID (`remote_project_id`), dann Pfad (`remote_full_path`); kein Fallback mehr. Mehrfachtreffer -> 409, kein Treffer -> 404.

## Konsequenzen
- Requests ohne Secret oder ohne gueltige Signatur/Token werden mit 401 abgewiesen.
- Admins muessen die Secrets im Redmine-Plugin-Settings-UI setzen, sonst schlagen Webhooks fehl.
- Minimale Latenz durch HMAC, keine externen Abhaengigkeiten.
- Ambigue Projekt-Mappings werden abgewiesen (409), fehlende Mappings mit 404; Admins muessen ProjectLinks pflegen.

## Status
- Implementiert
