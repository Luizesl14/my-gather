# 17 — Backend Shared DDD Spec

## Objetivo

Criar tipos compartilhados para DDD e Clean Architecture.

## Criar

- `backend/src/shared/domain/entity.ts`
- `backend/src/shared/domain/aggregate-root.ts`
- `backend/src/shared/domain/value-object.ts`
- `backend/src/shared/domain/domain-event.ts`
- `backend/src/shared/domain/result.ts`
- `backend/src/shared/application/use-case.ts`
- `backend/src/shared/application/event-bus.ts`

## Regras

- Domínio não importa Fastify, Prisma, Redis ou HTTP.
- `Result` representa sucesso/erro de regra.
- Eventos têm `eventName`, `aggregateId`, `occurredAt`.

## Critérios de aceite

- Tipos compilam.
- Teste unitário simples cobre `Result`.
