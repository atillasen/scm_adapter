# ADR 0007: Performanceziele fuer Webhook-Flow und Jobs

## Kontext
- Webhooks sollen zeitnah reagieren, ohne durch Mirror-Sync oder langlaufende API-Calls blockiert zu werden.
- Sidekiq/Redis ist als bevorzugter Adapter gesetzt; Inline-Fallback existiert.
- Bisher gab es keine expliziten Kennzahlen.

## Entscheidung
- Zielwerte definieren (Ausgangspunkt, spaeter nach Messung schaerfen):
  - Webhook-Latenz (Empfang bis Response): P95 < 2s, P99 < 5s bei normaler Last.
  - Queue-Wartezeit (Enqueue bis Start): P95 < 1s bei Sidekiq-Betrieb.
  - Job-Laufzeit: P95 < 5s fuer Standard-Sync, Mirror-Jobs duerfen laenger laufen, muessen aber getrennte Queue nutzen.
  - Fehlerquote Webhooks: < 0,1% 5xx im 24h-Schnitt (401/404/409 explizit ausgenommen, da fachliche Ablehnungen).
- Mirror-Sync laeuft in eigener Queue, um Webhooks nicht zu blockieren.
- Retries: Provider-API-Fehler mit Exponential Backoff, begrenzte Versuche (z.B. 5), danach Dead-Queue/Alert.

## Konsequenzen
- Messung der Metriken wird erforderlich (siehe ADR 0006); ohne Messung lassen sich Ziele nicht verifizieren.
- Deployment/Sidekiq-Konfig muss separate Queues erlauben (Webhook-Dispatch vs. Mirror).
- Inline-Fallback kann Ziele verfehlen; fuer Produktion ist Sidekiq Pflicht, um Latenzziele zu halten.

## Status
- Akzeptiert (Zielwerte als Startpunkt, nach Betriebserfahrungen anzupassen)
