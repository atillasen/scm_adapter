# ADR 0001: Datenbank & JSON-Spalten

## Kontext
- Redmine 6.0.0 (Rails 7.2) mit MySQL 8 als DB (Compose-Default). Plugin nutzt JSON-Felder fuer Mapping/Keywords.
- MySQL 8 verbietet Default-Werte auf JSON-Spalten; PostgreSQL erlaubt jsonb mit Default.

## Entscheidung
- Migration `003_create_scm_adapter_sync_rules` enthaelt zwei Pfade: MySQL nutzt `t.json` ohne Default, erlaubt `null: true`; PostgreSQL nutzt `jsonb` mit Default `{}` bzw. `[]`, `null: false`.
- Beibehalt von MySQL-Default im Compose, aber Code bleibt PG-kompatibel.

## Konsequenzen
- MySQL: Applikationslogik muss Null-Werte defensiv behandeln (Parser/Dispatcher sollten leere Hashes/Arrays bei Nil einsetzen).
- Bei Wechsel auf PostgreSQL sind Defaults vorhanden; keine Migrationsaenderung noetig.
- Tests sollten beide Pfade abdecken; aktuell keine DB-übergreifenden Tests vorhanden.

## Status
- Akzeptiert
