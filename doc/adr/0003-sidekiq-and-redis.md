# ADR 0003: Sidekiq & Redis als Background-Queue

## Kontext
- Plugin synchronisiert SCM-Ereignisse und kann asynchrone Jobs benoetigen (z.B. API-Aufrufe, Mapping).
- Redmine-Compose-Stack bringt Redis 7 und Sidekiq-Gems mit; ActiveJob kann Sidekiq verwenden.

## Entscheidung
- Sidekiq als Queue-Adapter nutzen; Redis als Backend (URL per `REDIS_URL`).
- Separater Container `redmine_sidekiq` mit eigenem Entrypoint (`sidekiq-entrypoint.sh`).

## Konsequenzen
- Betrieb: Redis muss verfuegbar sein; bei Ausfall bleiben Jobs liegen.
- App-Container und Sidekiq teilen Code ueber Volume-Mount, dadurch Hot-Reload von Plugin-Code im Dev-Setup.
- Monitoring/Retry-Strategie noch nicht beschrieben; kein Web UI fuer Sidekiq aktiviert.

## Status
- Akzeptiert
