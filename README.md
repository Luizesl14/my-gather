# Love+Robot — Escritório Virtual

Projeto de “escritório virtual” 2D com presença em tempo real, mapas, avatares e interações sociais.

## Stack

- Backend: Node.js + TypeScript (Fastify) + PostgreSQL + Redis + WebSocket
- Web: Flutter Web

## Estrutura do repositório

- `backend/`: API + realtime + domínios (DDD)
- `web/`: app Flutter Web
- `web/assets/`: sprites, tilesets, mapas e atlases
- `infra/`: arquivos de suporte (Postgres/Redis etc.)
- `docs/`: documentação “espelho” das specs
- `.specs/`: fila operacional, specs de contexto, pendências e histórico concluído

## Como começar (alto nível)

1. Leia a fila operacional em `.specs/00-implementation-sequence-spec.md`
2. Consulte `.specs/README.md` para entender `context/`, `todo/`, `pending/` e `done/`
3. Copie `.env.example` para `.env` e ajuste valores locais
4. Suba a infra local (docker compose) e rode backend + web
