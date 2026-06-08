# 33 — Web Network & Realtime Spec

## Objetivo

Criar clientes HTTP e WebSocket.

## Criar

- `web/lib/core/network/api_client.dart`
- `web/lib/core/realtime/realtime_client.dart`
- serializers DTO.

## Regras

- Token JWT anexado ao HTTP.
- Token JWT usado no handshake WebSocket.
- Reconexão com backoff.
- Eventos desconhecidos são logados, não quebram app.

## Critérios de aceite

- Cliente HTTP chama `/health`.
- WebSocket conecta e recebe ping/pong.
