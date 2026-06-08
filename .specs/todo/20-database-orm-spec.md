# 20 — Database ORM Spec

## Objetivo

Configurar acesso ao PostgreSQL com Prisma ou Drizzle.

## Criar

Se Prisma:

- `backend/prisma/schema.prisma`
- `backend/src/shared/infrastructure/database/prisma-client.ts`

Se Drizzle:

- `backend/src/shared/infrastructure/database/client.ts`
- `backend/src/shared/infrastructure/database/schema/`

## Regras

- Repositórios usam ORM apenas na infraestrutura.
- Domínio não conhece tabelas.
- Mappers convertem persistence model para domain model.

## Critérios de aceite

- Migration inicial roda.
- Client conecta usando `DATABASE_URL`.
