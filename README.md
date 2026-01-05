

# SCM Adapter – Redmine Plugin (GitLab/GitHub)

Languages: [English](#english) · [Deutsch](#deutsch) · [Türkçe](#türkçe)

```text
Tested with: Redmine 6.0.0 (Rails 7.2, Ruby 3.3)
Providers:   GitLab CE/EE, GitHub
Jobs:        Sidekiq recommended (inline fallback when disabled)
Locales:     en, de, tr
```

---

## English

### What it does
- Parses close keywords in commits / MRs / PRs (`Fixes #123`) and updates Redmine issues.
- Shows latest commits per issue (link, author, timestamp, mirror link to local repo).
- Soft-delete commit entries with required reason; writes a journal note.
- Webhook mode switch: plugin webhooks, core `/sys/fetch_changesets`, or both.
- Secrets required for all webhooks (GitHub HMAC, GitLab token).

### Install
Classic:
1) Copy to `REDMINE_ROOT/plugins/scm_adapter`.
2) `bundle install --without development test`
3) `bundle exec rake redmine:plugins:migrate NAME=scm_adapter RAILS_ENV=production`
4) Restart Redmine; run Sidekiq.

Docker (provided):
1) Adjust `.env.redmine`; use `infrastruktur/docker-compose.redmine.yml`.
2) `docker compose -f infrastruktur/docker-compose.redmine.yml up --build -d`
3) Migrations run in entrypoint; Sidekiq service included.

### Configure
- Administration → Plugins → SCM Adapter → Configure.
- Set base URL, token, webhook secret per provider (required, else 401).
- Webhook mode per provider: `both` (default) / `plugin_only` (/scm_adapter/webhooks/...) / `core_only` (/sys/fetch_changesets). Legacy global `webhook_mode` is still honored as fallback.
- Optional: mirror base path, git binary, comment-back, issue commits position (top/bottom).
- Repository entries must point to a local Git path (e.g., the mirror under `/usr/src/redmine/git-mirrors/...`). Using a remote HTTP(S) URL in Redmine’s repository settings will yield 404 when browsing.

### Webhooks
- GitLab: `POST /scm_adapter/webhooks/gitlab` with `X-Gitlab-Token`.
- GitHub: `POST /scm_adapter/webhooks/github` with `X-Hub-Signature-256` (HMAC-SHA256).
- Events: Push, Merge/Pull Request.
- Project resolution: first `remote_project_id`, then `remote_full_path`; conflicts → 409, missing → 404.
- URL pattern: `https://<your-redmine>/scm_adapter/webhooks/gitlab` (or `/github`); make sure the URL uses the proxy that terminates TLS, not the Puma HTTP port.

### Mirrors & repositories
- Saving a Project Link triggers a mirror sync (background job) into `mirror_base_path` (default `/usr/src/redmine/git-mirrors`) using `git_binary`; clone URL is built from provider base URL + token.
- Mirror sync can be skipped via `SCM_ADAPTER_SKIP_MIRROR_SYNC=1` (for migrations/tests). SSL can be relaxed via `SCM_ADAPTER_SSL_VERIFY=false` or `SCM_ADAPTER_CA_FILE=/path/to/ca.pem`.
- After sync, a Redmine Git repository entry is created/updated to point at the mirror (identifier `gitlab`/`github`).

### Project links
- Per project, create a link with provider (`gitlab`/`github`), `remote_project_id` and `remote_full_path` (both required). Optional per-project `clone_base_url` override.
- If the link is missing/mismatched, webhook resolution returns 404/409 and mirror sync fails.

### Comment back
- Automatic: when a close keyword updates an issue, a background job posts a commit comment back to GitLab/GitHub with the Redmine issue reference.
- Manual: from the repository revision view, authenticated users with `manage_repository` can send a comment to the remote commit (with preview). The plugin appends the Redmine username marker.

### Rake / CLI
- `bundle exec rake scm_adapter:sync_all`: enqueue sync for all linked projects.
- `bundle exec rake scm_adapter:mirror:health` (`FIX=1` to auto-fix): checks mirror paths and repo wiring.
- `bundle exec rake scm_adapter:backfill:commits` (`PROJECT=<identifier>`, `SKIP_SYNC=1`, `STRICT=1`): imports historical commits using close keywords.

### Status mapping & close keywords
- Configurable via plugin settings (`issue_status_mapping` JSON, `close_keywords` array) or per project via sync rules; defaults map `opened/in_progress/merged/closed` to Redmine statuses and `fixes/closes/resolves` as keywords.
- Mapping resolves Redmine status IDs by name; invalid names fall back to the issue’s current status.

### Repository history
- Use the `Diff from` / `Diff to` columns in the repository revision list to pick the start/end commits before clicking `View differences`.

### Issue commits panel
- Shows up to 20 recent entries. Mirror link points to the local repository revision.
- Delete flow asks for a reason, hides the entry (soft delete), and adds a journal note.

### Background jobs
- Sidekiq recommended; if disabled, jobs run inline via ActiveJob.

### License
Apache License 2.0. See LICENSE-APACHE-2.0.txt.

---

## Deutsch

### Was es tut
- Erkannt werden Close-Keywords in Commits / MRs / PRs (`Fixes #123`) und Redmine-Issues werden aktualisiert.
- Ticketansicht zeigt die letzten Commits pro Issue (Link, Autor, Zeit, Mirror-Link zur lokalen Repo-Revision).
- Commit-Einträge lassen sich mit Begründung ausblenden; ein Journal-Eintrag wird geschrieben.
- Webhook-Modus umschaltbar: Plugin-Webhooks, Core-WS `/sys/fetch_changesets` oder beides.
- Webhook-Secrets sind Pflicht (GitHub HMAC, GitLab Token).

### Installation
Klassisch:
1) Nach `REDMINE_ROOT/plugins/scm_adapter` kopieren.
2) `bundle install --without development test`
3) `bundle exec rake redmine:plugins:migrate NAME=scm_adapter RAILS_ENV=production`
4) Redmine neu starten; Sidekiq starten.

Docker (bereitgestellt):
1) `.env.redmine` anpassen; Compose unter `infrastruktur/docker-compose.redmine.yml`.
2) `docker compose -f infrastruktur/docker-compose.redmine.yml up --build -d`
3) Migrationen laufen im Entrypoint; Sidekiq-Service ist enthalten.

### Konfiguration
- Administration → Plugins → SCM Adapter → Konfigurieren.
- Basis-URL, Token, Webhook-Secret pro Provider setzen (Pflicht, sonst 401).
- Webhook-Modus je Provider: `both` (Standard) / `plugin_only` (/scm_adapter/webhooks/...) / `core_only` (/sys/fetch_changesets); globales `webhook_mode` bleibt als Fallback erhalten.
- Optional: Mirror-Pfad, Git-Binary, Kommentar-Rueckspiel, Position der Commits im Ticket (oben/unten).
- Repository-Einträge müssen auf einen lokalen Git-Pfad zeigen (z. B. den Mirror unter `/usr/src/redmine/git-mirrors/...`). Ein Remote-HTTP(S)-Link in den Repository-Einstellungen führt beim Browsen zu 404.

### Webhooks
- GitLab: `POST /scm_adapter/webhooks/gitlab` mit `X-Gitlab-Token`.
- GitHub: `POST /scm_adapter/webhooks/github` mit `X-Hub-Signature-256` (HMAC-SHA256).
- Events: Push, Merge/Pull Request.
- Projektauflösung: zuerst `remote_project_id`, dann `remote_full_path`; Konflikt → 409, kein Treffer → 404.
- URL-Schema: `https://<dein-redmine>/scm_adapter/webhooks/gitlab` (bzw. `/github`); der Aufruf muss über den Proxy laufen, der TLS terminiert – nicht direkt auf den Puma-HTTP-Port.

### Mirrors & Repository-Einträge
- Beim Speichern eines Projekt-Links wird ein Mirror-Sync (Background-Job) ins `mirror_base_path` (Standard `/usr/src/redmine/git-mirrors`) mit `git_binary` angestoßen; die Clone-URL wird aus Basis-URL + Token gebaut.
- Mirror-Sync lässt sich per `SCM_ADAPTER_SKIP_MIRROR_SYNC=1` überspringen (Migration/Tests). TLS-Checks steuerbar via `SCM_ADAPTER_SSL_VERIFY=false` oder `SCM_ADAPTER_CA_FILE=/pfad/ca.pem`.
- Nach dem Sync wird/bleibt ein Redmine-Git-Repository-Eintrag auf den Mirror gesetzt (Identifier `gitlab`/`github`).

### Projekt-Links
- Pro Projekt einen Link mit Provider (`gitlab`/`github`), `remote_project_id` und `remote_full_path` anlegen (Pflicht). Optional pro Projekt `clone_base_url` überschreiben.
- Fehlt der Link oder ist er falsch, liefern Webhooks 404/409 und der Mirror-Sync schlägt fehl.

### Comment-Back
- Automatisch: Wenn ein Close-Keyword den Status ändert, sendet ein Job einen Commit-Kommentar mit Redmine-Issue-Referenz an GitLab/GitHub.
- Manuell: In der Repository-Revision-Ansicht können berechtigte Nutzer (`manage_repository`) Kommentare an den Remote-Commit schicken (mit Vorschau). Der Redmine-Username wird angehängt.

### Rake / CLI
- `bundle exec rake scm_adapter:sync_all`: Sync für alle verknüpften Projekte einreihen.
- `bundle exec rake scm_adapter:mirror:health` (`FIX=1` zum Reparieren): prüft Mirror-Pfade und Repository-Verknüpfung.
- `bundle exec rake scm_adapter:backfill:commits` (`PROJECT=<identifier>`, `SKIP_SYNC=1`, `STRICT=1`): importiert historische Commits anhand der Close-Keywords.

### Status-Mapping & Close-Keywords
- Einstellbar über Plugin-Settings (`issue_status_mapping` als JSON, `close_keywords` als Array) oder pro Projekt via Sync-Regel; Default: `opened/in_progress/merged/closed` auf Redmine-Status, Keywords `fixes/closes/resolves`.
- Mapping löst Statusnamen auf IDs auf; ungültige Namen fallen auf den aktuellen Issue-Status zurück.

### Repository-Historie
- In der Repository-Historie die Spalten `Diff von` / `Diff bis` nutzen, um Start- und End-Commit für den Diff zu setzen; danach auf "Unterschiede anzeigen" klicken.

### Commit-Liste im Ticket
- Zeigt bis zu 20 Einträge; Mirror-Link führt zur lokalen Repository-Revision.
- Lösch-Flow verlangt eine Begründung, blendet den Eintrag aus (soft delete) und schreibt einen Journal-Eintrag.

### Hintergrundjobs
- Sidekiq empfohlen; ist es aus, laufen Jobs inline via ActiveJob.

### Lizenz
Apache License 2.0. Siehe LICENSE-APACHE-2.0.txt.

---

## Türkçe

### Ne yapar
- Commit / MR / PR metinlerinde kapatma anahtar kelimelerini (`Fixes #123`) yakalar ve Redmine kaydını günceller.
- Talep sayfasında son commit'leri gösterir (link, yazar, zaman, yerel depo revizyonuna ayna linki).
- Commit kaydı gerekçeyle gizlenebilir; günlük notu eklenir.
- Webhook modu seçilebilir: eklenti web kancaları, çekirdek `/sys/fetch_changesets` veya ikisi birlikte.
- Webhook sırları zorunlu (GitHub HMAC, GitLab token).

### Kurulum
Klasik:
1) `REDMINE_ROOT/plugins/scm_adapter` içine kopyala.
2) `bundle install --without development test`
3) `bundle exec rake redmine:plugins:migrate NAME=scm_adapter RAILS_ENV=production`
4) Redmine'i yeniden başlat; Sidekiq'i çalıştır.

Docker (hazır):
1) `.env.redmine` dosyasını düzenle; `infrastruktur/docker-compose.redmine.yml` kullan.
2) `docker compose -f infrastruktur/docker-compose.redmine.yml up --build -d`
3) Migrasyonlar entrypoint'te çalışır; Sidekiq servisi dahildir.

### Yapılandırma
- Yönetim → Eklentiler → SCM Adaptörü → Yapılandır.
- Her sağlayıcı için temel URL, token ve webhook gizli anahtarını ayarla (zorunlu, aksi halde 401).
- Webhook modu sağlayıcı bazında: `both` (varsayılan) / `plugin_only` (/scm_adapter/webhooks/...) / `core_only` (/sys/fetch_changesets); eski global `webhook_mode` yedeğe düşer.
- Opsiyonel: ayna dizini, git ikilisi, yorum geri gönderimi, bilette commit'lerin konumu (üst/alt).
- Depo kayıtları yerel bir Git yolunu göstermeli (ör. `/usr/src/redmine/git-mirrors/...` altındaki ayna). Redmine depo ayarlarına HTTP(S) uzak URL yazarsan gezinirken 404 alırsın.

### Web kancaları
- GitLab: `POST /scm_adapter/webhooks/gitlab` ve `X-Gitlab-Token`.
- GitHub: `POST /scm_adapter/webhooks/github` ve `X-Hub-Signature-256` (HMAC-SHA256).
- Olaylar: Push, Merge/Pull Request.
- Proje eşleşmesi: önce `remote_project_id`, sonra `remote_full_path`; çakışma → 409, bulunamadı → 404.
- URL deseni: `https://<redmine>/scm_adapter/webhooks/gitlab` (veya `/github`); TLS’i sonlandıran proxy üzerinden çağırın, Puma’nın HTTP portuna doğrudan HTTPS göndermeyin.

### Ayna (mirror) ve depo kaydı
- Proje bağlantısı kaydedildiğinde arka planda bir ayna senkronu `mirror_base_path` (varsayılan `/usr/src/redmine/git-mirrors`) altına başlar; clone URL’i temel URL + token ile kurulur.
- `SCM_ADAPTER_SKIP_MIRROR_SYNC=1` ile (örn. migration/test) senkronu atlayabilirsiniz; TLS doğrulamasını `SCM_ADAPTER_SSL_VERIFY=false` veya `SCM_ADAPTER_CA_FILE=/yol/ca.pem` ile ayarlayın.
- Senkron sonrası Redmine’da Git deposu girişi ayna yoluna bağlanır (`gitlab`/`github` identifier).

### Proje bağlantıları
- Her proje için bir bağlantı oluşturun: sağlayıcı (`gitlab`/`github`), `remote_project_id` ve `remote_full_path` zorunlu. İsteğe bağlı proje bazlı `clone_base_url` geçersiz kılma.
- Bağlantı eksik/yanlış ise web kancaları 404/409 döner ve ayna senkronu başarısız olur.

### Geri yorum (comment back)
- Otomatik: Close-keyword ile durum güncellendiğinde iş, GitLab/GitHub’a Redmine talep referansı içeren commit yorumu gönderir.
- Manuel: Depo revizyon görünümünden yetkili kullanıcılar (`manage_repository`) uzaktaki commite yorum gönderebilir (önizleme var); Redmine kullanıcı adı eklenir.

### Rake / CLI
- `bundle exec rake scm_adapter:sync_all`: Tüm bağlı projeler için senkron kuyruğa ekler.
- `bundle exec rake scm_adapter:mirror:health` (`FIX=1` onarım): ayna yollarını ve depo bağlantısını kontrol eder.
- `bundle exec rake scm_adapter:backfill:commits` (`PROJECT=<identifier>`, `SKIP_SYNC=1`, `STRICT=1`): geçmiş commit’leri close-keyword’lerle içeri alır.

### Durum eşleme ve close-keyword’ler
- Eşleme ayarları eklenti konfigünde (`issue_status_mapping` JSON, `close_keywords` dizi) veya proje bazlı sync kuralıyla yapılabilir; varsayılan eşleme `opened/in_progress/merged/closed` ve anahtar kelimeler `fixes/closes/resolves`.
- Statü adları Redmine’daki ID’lere çözümlenir; geçersiz adlar mevcut talep durumunda bırakır.

### Depo geçmişi
- Depo revizyon listesinde `Diff başlangıç` / `Diff bitiş` sütunlarıyla diff için başlangıç ve bitiş commit'lerini seçin; ardından "View differences" düğmesine basın.

### Talep sayfası commit listesi
- En fazla 20 kayıt gösterir; ayna linki yerel depo revizyonuna gider.
- Silme akışı gerekçe ister, kaydı gizler (soft delete) ve günlük notu yazar.

### Arka plan işleri
- Sidekiq önerilir; kapalıysa işler ActiveJob ile satır içi çalışır.

### Lisans
Apache License 2.0. LICENSE-APACHE-2.0.txt dosyasına bakınız.
