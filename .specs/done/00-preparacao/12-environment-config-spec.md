# 12 — Environment Config Spec

## Objetivo

Definir variáveis de ambiente e validação de configuração.

## Criar

- `.env.example`
- `backend/.env.example`
- `web/.env.example`

## Variáveis backend

- `NODE_ENV`
- `API_PORT`
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `CORS_ORIGIN`

## Variáveis web

- `WEB_API_BASE_URL`
- `WEB_WS_URL`
- `APP_THEME_DEFAULT`

## Critérios de aceite

- Nenhum segredo real é salvo.
- Backend valida env ao iniciar.
- Web documenta URLs locais.
