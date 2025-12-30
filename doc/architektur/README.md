# Architekturuebersicht / Architecture / Mimari

## TL;DR
- Redmine 6.0.0 (Rails 7.2, Ruby 3.3), Docker Compose (MySQL 8, Redis 7, Puma, Sidekiq)
- Rails Engine (`lib/scm_adapter/engine.rb`), routes in `config/routes.rb`
- Providers: GitLab, GitHub; webhooks require secrets/tokens
- Jobs: Sidekiq recommended; inline fallback if disabled

## Komponenten / Components
- Web UI & settings: `app/controllers/scm_adapter/settings_controller.rb`, views `app/views/scm_adapter/settings`, stores `IntegrationSetting`
- Webhooks: `app/controllers/scm_adapter/webhooks/{github,gitlab}_controller.rb`, CSRF skip, signature/token check, project resolution via `ProjectLink` (id → path), conflict 409, not found 404, dispatches to Sync
- Sync/Services: `app/services/scm_adapter/sync/{dispatcher.rb,mapping.rb,close_keyword_parser.rb}` (commit parsing, close keywords, status mapping)
- Jobs: `app/jobs/scm_adapter/{github_sync_job.rb,gitlab_sync_job.rb,mirror_sync_job.rb,comment_back_job.rb}`
- Clients: `app/services/scm_adapter/clients/{github_client.rb,gitlab_client.rb}`
- Models: `ProjectLink`, `IntegrationSetting`, `SyncRule`, `CommitEvent`
- Hooks: issue view renders commit list (provider, SHA link, message, author, time, mirror)

## Datenmodell / Data model
- `scm_adapter_project_links`: project_id, provider, remote_full_path (unique), remote_project_id (unique per provider)
- `scm_adapter_integration_settings`: project_id, provider, base_url, token, webhook_secret, options
- `scm_adapter_sync_rules`: project_id, status/keyword mappings (JSON)
- `scm_adapter_commit_events`: issue_id, provider, sha, author, url, message, pushed_at, deleted_at/by/reason (soft delete)

## Webhook Flow (kurz)
1. POST with event headers (GitHub: `X-GitHub-Event` + `X-Hub-Signature-256`, GitLab: `X-Gitlab-Event` + `X-Gitlab-Token`).
2. Secret check (401 if missing/invalid).
3. Resolve project via `ProjectLink` (id → path). Conflict → 409, none → 404.
4. Dispatcher handles `handle_commit` and `handle_merge_status`, persists `CommitEvent`, optional comment-back.
5. Respond `{ ok: true }` or appropriate error.

## Hintergrundjobs / Background jobs
- Sidekiq (Redis) recommended; `sidekiq_enabled` flag, otherwise ActiveJob inline.
- Mirror-Sync keeps bare repos under `mirror_base_path`; RepositoryManager registers the mirror as Redmine repo.

## Infrastruktur (Docker/Compose)
- `infrastruktur/redmine/Dockerfile`: builds Redmine, copies plugin, writes `config/database.yml`, installs gems (sidekiq, redis, faraday, faraday-retry, multi_json, connection_pool).
- Entrypoint: bundle check/install, DB migrate, plugin migrate, start Puma.
- `docker-compose.redmine.yml`: services db, redis, redmine (Puma), sidekiq; mounts `..:/usr/src/redmine/plugins/scm_adapter`.

## Sicherheit / Caveats
- Secrets/tokens stored in settings (plaintext); protect admin access.
- Webhook secrets mandatory.
- Known cosmetic warning: duplicate `stringio` specs from Bundler.

## Tests
- `test/unit`: clients, close_keyword_parser.
- `test/integration`: webhooks (GitHub, GitLab).

## Kurz starten / Quick start
- `docker compose -f infrastruktur/docker-compose.redmine.yml up -d --build`
- App: http://localhost:8090, Sidekiq runs alongside.

## Turkish quick note
- Aynı akış: Webhook gizli anahtarı zorunlu, proje eşlemesi `ProjectLink` ile (önce id sonra yol), Sidekiq önerilir, mirror repo Redmine içinde varsayılan repo olarak kullanılabilir.
