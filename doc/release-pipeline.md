# Reproduzierbare Release-Pipeline (GitLab → GitHub)

**Use Case**  
- Ziel: Aus dem GitLab-Repo deterministische Release-Pakete (tar/zip) aus einer Whitelist bauen, automatisiert per GitLab-CI; Artefakte werden als GitHub-Release hochgeladen. Der Job schlägt fehl, wenn Pakete fehlen oder vom Whitelist-Inhalt abweichen.  
- Inputs: Git-Tag (Version), Whitelist (z.B. `app`, `config`, `db/migrate`, `lib`, `assets`, `init.rb`, `README.md`, `LICENSE*`, `doc/**`, `Gemfile*`, `scm_adapter.gemspec`), Ausschlüsse (`test`, `tmp`, `log`, `.git`, `node_modules`, `vendor/cache`, Secrets).  
- Outputs: `dist/scm_adapter-$VERSION.tar.gz` und `dist/scm_adapter-$VERSION.zip`, deterministisch (sortierte Files, feste mtime/owner), Checksummen (sha256) im Job-Log, GitHub-Release mit diesen Assets.

---

## Technische To-Dos

1) **Pfad-Whitelist/Ausschlüsse finalisieren**  
   - Einschließen (Allowlist, Top-Level): `app`, `assets`, `config`, `db/migrate`, `doc`, `lib`, `init.rb`, `Gemfile`, `Gemfile.lock`, `scm_adapter.gemspec`, `LICENSE*`, `NOTICE`, `README.md`, `RELEASE.md`, `Rakefile`.  
   - Optional einschließen: `config.ru`, `backfill_mr.rb` (falls für Betrieb nötig), `config/locales` (liegt unter `config`).  
   - Ausschließen: `.git`, `.gitlab-ci.yml` (nur falls nicht im Paket gewünscht), `test/`, `tmp/`, `log/`, `node_modules/`, `vendor/`, `coverage/`, `.bundle/`, persönliche Configs/Secrets.  
   - Optional: `scripts/allowed_paths.txt` pflegen (vollständige Pfad-Liste aus `tar tzf ... | sort`) zur Diff-Prüfung.

2) **Deterministisches Build-Skript erstellen (`scripts/build_release.sh`)**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   VERSION="${VERSION:-${CI_COMMIT_TAG:-dev}}"
   DIST="dist"
   mkdir -p "$DIST"
   ALLOWLIST=(
     app config db/migrate lib assets init.rb README.md LICENSE* doc
     Gemfile Gemfile.lock scm_adapter.gemspec
   )
   tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
       -czf "$DIST/scm_adapter-$VERSION.tar.gz" "${ALLOWLIST[@]}"
   zip -X -r "$DIST/scm_adapter-$VERSION.zip" "${ALLOWLIST[@]}"

   tar tzf "$DIST/scm_adapter-$VERSION.tar.gz" | LC_ALL=C sort > "$DIST/tar-contents.txt"
   # Optional: diff -u scripts/allowed_paths.txt dist/tar-contents.txt

   test -f "$DIST/scm_adapter-$VERSION.tar.gz"
   test -f "$DIST/scm_adapter-$VERSION.zip"
   sha256sum "$DIST"/scm_adapter-"$VERSION".{tar.gz,zip}
   ```
   - Vorab kann `git status --porcelain` sicherstellen, dass der Arbeitsbaum sauber ist.  
   - Skript bricht ab, wenn Artefakte fehlen oder die Allowlist-Diff nicht leer ist.

3) **GitLab-CI konfigurieren (`.gitlab-ci.yml`)**
   ```yaml
   stages: [package, release]

   variables:
     RUBYOPT: "-W0"

   build_release:
     stage: package
     image: ruby:3.2-alpine
     before_script:
       - apk add --no-cache tar zip git
       - bundle install --without development test || true
     script:
       - chmod +x scripts/build_release.sh
       - VERSION="${CI_COMMIT_TAG#v}" scripts/build_release.sh
     artifacts:
       paths: [dist/*.tar.gz, dist/*.zip, dist/tar-contents.txt]
       expire_in: 1 week
     rules:
       - if: '$CI_COMMIT_TAG'

   publish_github:
     stage: release
     needs: [build_release]
     image: alpine:3.19
     variables:
       GITHUB_REPO: "owner/scm_adapter"  # im GitLab-UI setzen/überschreiben
     before_script:
       - apk add --no-cache curl git github-cli
     script:
       - test -f dist/*.tar.gz && test -f dist/*.zip
       - gh auth status || gh auth login --with-token <<< "$GITHUB_TOKEN"
       - gh release create "$CI_COMMIT_TAG" dist/*.tar.gz dist/*.zip --repo "$GITHUB_REPO" --notes "Automatischer Release-Build"
       - gh release view "$CI_COMMIT_TAG" --repo "$GITHUB_REPO"
     rules:
       - if: '$CI_COMMIT_TAG'
   ```

4) **Secrets/Variablen in GitLab setzen**  
   `GITHUB_TOKEN` (Scope `repo`, masked/protected), `GITHUB_REPO` (z.B. `owner/scm_adapter`). Optional Tag-Mapping von `vX.Y.Z` → `X.Y.Z`.

5) **Fail-Fast/Validierung**  
   Artefakte müssen existieren (`test -f …`), Allowlist-Diff muss leer sein, `sha256sum` im Log, optional Abbruch bei unsauberem Git-Tree.

6) **Dokumentation**  
   Abschnitt “Release-Build” im Repo: Whitelist/Ausschlüsse, deterministische Flags, CI-Trigger (Tags), Variablen, Fehlerbedingungen (fehlende Artefakte, Allowlist-Diff).

7) **Probelauf**  
   Tag (z.B. `v0.1.0`) pushen → Pipeline beobachten → `tar tzf`/`zipinfo` der Artefakte prüfen → GitHub-Release (Assets/Checksummen) verifizieren.

---

## Schritt-für-Schritt (für CI-Einsteiger)

1. **Voraussetzungen prüfen**  
   - GitLab-Projekt mit aktivem Runner.  
   - GitHub-Account mit Repo-Rechten, in dem die Releases landen sollen.  
   - Auf deinem Rechner: `git`, Editor.

2. **Whitelist definieren**  
   - Öffne das Repo und entscheide, welche Verzeichnisse/Dateien ins Release gehören (siehe Inputs oben).  
   - Optional: Lege `scripts/allowed_paths.txt` an, liste darin jede erwartete Pfadzeile (z.B. mit `tar tzf ... | sort` erzeugen und übernehmen).

3. **Build-Skript anlegen**  
   - Datei `scripts/build_release.sh` erzeugen (siehe Skript oben), als ausführbar markieren: `chmod +x scripts/build_release.sh`.  
   - Ordner `scripts/` anlegen, falls er fehlt: `mkdir -p scripts`.  
   - Wichtige Schalter:  
     - `set -euo pipefail` → Skript bricht bei Fehlern ab.  
     - `tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner` → sorgt für reproduzierbares tar.  
     - `zip -X` → entfernt Zeitstempel/Metadaten für reproduzierbares zip.  
     - `test -f ...` → bricht ab, wenn Artefakte fehlen.  
     - `sha256sum` → liefert Prüfsummen ins Log.

4. **Optional: Allowlist-Check aktivieren**  
   - Generiere einmal `scripts/allowed_paths.txt`: `tar tzf dist/scm_adapter-<version>.tar.gz | sort > scripts/allowed_paths.txt`.  
   - Ergänze im Skript `diff -u scripts/allowed_paths.txt dist/tar-contents.txt` damit der Job bei Abweichung abbricht.

5. **CI-Datei ergänzen**  
   - In `.gitlab-ci.yml` den Block aus Abschnitt 3 einfügen.  
   - `GITHUB_REPO` im Job anpassen oder als Variable setzen.

6. **GitHub Token erstellen**  
   - GitHub → Settings → Developer settings → Personal access tokens.  
   - Token mit Scope `repo` erstellen, kopieren.  
   - **Wichtig**: Token nur einmal sichtbar, sicher ablegen.

7. **Variablen in GitLab setzen**  
   - Projekt → Settings → CI/CD → Variables:  
     - `GITHUB_TOKEN` (Masked, Protected).  
     - `GITHUB_REPO` (Format `owner/repo`).  
   - Optional: `VERSION_PREFIX` oder ähnliche Hilfsvariablen.

8. **Testlauf lokal (optional)**  
   - `VERSION=0.0.0 scripts/build_release.sh` ausführen.  
   - Prüfen: `ls dist`, `tar tzf dist/...tar.gz | head`, `sha256sum dist/*`.

9. **Erster Pipeline-Lauf**  
   - Git-Tag setzen: `git tag v0.1.0 && git push origin v0.1.0`.  
   - Pipeline in GitLab beobachten: `build_release` → `publish_github`.  
   - Im Job-Log prüfen: `sha256sum`, keine Fehlermeldungen, Artefakte erzeugt.

10. **Verifikation auf GitHub**  
    - Release `v0.1.0` sollte existieren, Assets (`tar.gz`, `zip`) angehängt.  
    - Prüfe Größen/Downloads, optional `gh release view v0.1.0 --repo owner/repo`.

---

## Warum diese Flags/Checks?
- **Deterministisch**: gleiche Eingabe → gleiche Artefakt-Hashes. `--sort=name` und `--mtime=@0` verhindern zeit- und reihenfolgebedingte Unterschiede.  
- **Fail-Fast**: `set -euo pipefail` und `test -f ...` stoppen den Job sofort, wenn etwas fehlt.  
- **Allowlist-Diff**: schützt vor versehentlichen Dateien im Paket (z.B. Secrets, Build-Outputs).  
- **Sha256 im Log**: erleichtert Verifikation und späteres Hash-Pinning.

---

## Hinweise zu GitLab-Runnern
- Der gezeigte Job nutzt Docker-Images (`ruby:3.2-alpine`, `alpine:3.19`). Stelle sicher, dass dein Runner ein Docker-Executor ist oder die Images pullen darf.  
- Bei Shell-Runnern müssen `tar`, `zip`, `git`, `gh` lokal installiert sein; ggf. Paketmanager verwenden (`apt`, `yum`).  
- Falls `bundle install` nicht nötig ist, kannst du die Zeile entfernen oder `|| true` belassen, damit fehlende Gems den Build nicht stoppen.

## Häufige Fehler & Fixes
- **Pipeline failt bei `gh auth`**: `GITHUB_TOKEN` fehlt oder hat falschen Scope (`repo`). In GitLab als Masked/Protected Variable setzen und Runner neu starten.  
- **Keine Artefakte gefunden**: Prüfe, ob `scripts/build_release.sh` mit `test -f ...` abbricht; Inhalte der Whitelist stimmen evtl. nicht. `tar-contents.txt` ansehen.  
- **Allowlist-Diff schlägt an**: Neue Datei hinzugekommen? Entweder in `scripts/allowed_paths.txt` ergänzen oder aus dem Paket ausschließen.  
- **Tag-Name vs. Version**: Wenn Tags mit `v` beginnen, aber die Version ohne `v` sein soll, im Skript `VERSION="${CI_COMMIT_TAG#v}"` nutzen (wie im Beispiel).  
- **Runner findet Images nicht**: Prüfe Registry-Zugriff; ggf. Mirror-Registry verwenden oder Basisimage anpassen.

## Akzeptanz-Checkliste
- [ ] Tar/Zip werden im Job erzeugt, enthalten nur Whitelist.  
- [ ] Job schlägt fehl, wenn Artefakte fehlen oder Allowlist-Diff auftritt.  
- [ ] Artefakte deterministisch (sort, mtime, owner).  
- [ ] GitHub-Release mit beiden Assets wird erstellt; Fehler beim Upload brechen Job.
