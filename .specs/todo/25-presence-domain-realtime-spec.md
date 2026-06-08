# 25 — Presence Domain & Realtime Spec

## Objetivo

Implementar presença, sessão, movimento e status em tempo real.

## Entidades

- `Session`
- `AvatarPresence`
- `AvatarPosition`

## Eventos WebSocket

- `workspace:join`
- `workspace:leave`
- `workspace:user.joined`
- `workspace:user.left`
- `avatar:move`
- `avatar:stop`
- `avatar:moved`
- `presence:status.change`
- `presence:status.changed`

## Regras

- Movimento é validado no backend.
- Client interpola usuários remotos.
- Status `Away` por inatividade.
- WebSocket caiu: offline após timeout.

## Critérios de aceite

- Dois usuários veem movimento um do outro.
- Avatar não atravessa colisão validada.
