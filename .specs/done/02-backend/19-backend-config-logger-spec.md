# 19 — Backend Config & Logger Spec

## Objetivo

Criar configuração validada e logging base.

## Criar

- `backend/src/shared/infrastructure/config/env.ts`
- `backend/src/shared/infrastructure/config/config.ts`
- `backend/src/shared/infrastructure/logger/logger.ts`

## Regras

- Env obrigatório falha no boot.
- Logger não deve expor segredos.
- Logs mínimos: boot, erro, request id e websocket connect/disconnect.

## Critérios de aceite

- App não inicia sem `JWT_SECRET`.
- Logger é injetável em use cases via porta quando necessário.
