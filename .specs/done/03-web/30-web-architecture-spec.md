# 30 — Web Architecture Spec

## Objetivo

Criar arquitetura Flutter por core, shared e features.

## Criar

- `web/lib/core/config/`
- `web/lib/core/theme/`
- `web/lib/core/router/`
- `web/lib/core/network/`
- `web/lib/core/realtime/`
- `web/lib/core/storage/`
- `web/lib/core/errors/`
- `web/lib/features/`
- `web/lib/shared/`

## Estrutura por feature

- `domain/`
- `application/`
- `data/`
- `presentation/`

## Critérios de aceite

- Feature não acessa infraestrutura de outra feature diretamente.
- Widgets não contêm regra de negócio.
