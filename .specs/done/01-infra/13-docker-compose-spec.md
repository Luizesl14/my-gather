# 13 — Docker Compose Spec

## Objetivo

Criar ambiente local com PostgreSQL e Redis.

## Criar

- `docker-compose.yml`
- `infra/postgres/`
- `infra/redis/`

## Serviços

- `postgres`: porta `5432`, volume persistente, healthcheck.
- `redis`: porta `6379`, volume opcional, healthcheck.

## Critérios de aceite

- `docker compose config` passa.
- `docker compose up -d postgres redis` sobe.
- Healthchecks ficam saudáveis.

## Não fazer ainda

- Não containerizar backend/web nesta etapa.
