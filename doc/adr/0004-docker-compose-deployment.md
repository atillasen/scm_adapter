# ADR 0004: Deployment via Docker Compose

## Kontext
- Entwicklung/Tests sollen reproduzierbar mit minimalem Setup laufen.
- Dienste: MySQL 8, Redis 7, Redmine-App (Puma) und Sidekiq.

## Entscheidung
- Nutzung von `docker-compose.redmine.yml` mit Build aus `infrastruktur/redmine/Dockerfile`.
- Plugin wird per Volume-Mount (`..:/usr/src/redmine/plugins/scm_adapter`) eingebunden, damit Codeaenderungen ohne Neu-Build verfuegbar sind.
- Portmapping 8090->3000 fuer App-Zugriff; gemeinsame Network `net`.

## Konsequenzen
- Build enthaelt Redmine 6.0.0 Clone, schreibt `config/database.yml`, fuegt benoetigte Gems hinzu.
- Secrets/ENV: `SECRET_KEY_BASE`, `REDMINE_DB_*`, `REDIS_URL`; im Dev .env setzen.
- Volume-Mount ueberschreibt Plugin aus dem Image; sicherstellen, dass lokale Quellen konsistent sind.

## Status
- Akzeptiert
