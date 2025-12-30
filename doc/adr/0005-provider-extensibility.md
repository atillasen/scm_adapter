# ADR 0005: Provider-Erweiterbarkeit

## Kontext
- Aktuell unterstuetzt der SCM Adapter GitHub und GitLab.
- Kuenftig sollen weitere Provider (z.B. Bitbucket) eingebunden werden koennen, ohne Kernlogik zu duplizieren.
- Webhook-Handling, API-Clients und Mapping/Sync teilen sich bereits gemeinsame Konzepte (Events, Projektauflosung, Close-Keywords).

## Entscheidung
- Provider-Schichten klar entkoppeln:
  - Webhook-Controller pro Provider, aber gemeinsame Dispatcher-Schnittstelle (Commit/MR/PR-Events).
  - API-Client pro Provider, aber gemeinsame Client-Signatur fuer Fetch/Lookup.
  - Mapping/Sync bleibt provider-agnostisch; Provider-spezifische Felder werden in einer Transformationsschicht normalisiert.
- Neue Provider muessen nur Webhook-Parser, Client und eventuelle Mapping-Adapter implementieren; Kern-Services bleiben unveraendert.
- ADRs dokumentieren Provider-Neuzugaenge; Tests muessen die Normalisierung abdecken.

## Konsequenzen
- Onboarding weiterer Provider erfordert kein Umschreiben der bestehenden Logik, nur neue Adapter/Parser.
- Testaufwand steigt pro Provider, aber Kernpfade bleiben stabil.
- Gemeinsame Schnittstellen zwingen zu konsistenter Event-Form und erleichtern Monitoring/Fehlerbilder.

## Status
- Akzeptiert
