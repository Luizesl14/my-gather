# 18 — Backend Module Folders Spec

## Objetivo

Criar diretórios dos bounded contexts.

## Módulos

- `identity`
- `workspace`
- `presence`
- `interaction`
- `communication`
- `meeting`
- `avatar`
- `notification`
- `asset`
- `billing`

## Estrutura por módulo

- `domain/entities/`
- `domain/value-objects/`
- `domain/events/`
- `domain/services/`
- `domain/repositories/`
- `application/use-cases/`
- `application/commands/`
- `application/queries/`
- `application/ports/`
- `infrastructure/persistence/`
- `infrastructure/mappers/`
- `presentation/http/`
- `presentation/schemas/`

## Critérios de aceite

- Todos os módulos seguem a mesma estrutura.
- Não há regra de negócio fora de `domain`/`application`.
