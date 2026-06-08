# 10 — Monorepo Structure Spec

## Objetivo

Criar a estrutura raiz do projeto para backend, web, infra, documentação e scripts.

## Criar

- `backend/`
- `web/`
- `infra/`
- `docs/`
- `scripts/`
- `README.md`
- `.gitignore`

## Regras

- Não misturar código backend e web.
- `infra/` contém apenas configuração local/deploy.
- `docs/` contém documentação estável, não specs temporárias.
- `scripts/` contém automações executáveis e pequenas.

## Critérios de aceite

- Pastas existem.
- `README.md` explica o produto, stack e como iniciar.
- `.gitignore` cobre Node, Flutter, Docker, logs, env, build e cache.
