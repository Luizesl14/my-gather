# 22 — Identity API Spec

## Objetivo

Expor autenticação e organização via REST.

## Endpoints

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- `GET /auth/me`
- `POST /organizations`
- `GET /organizations`
- `GET /organizations/:id`
- `POST /organizations/:id/invitations`
- `POST /invitations/:token/accept`

## Regras

- Payloads validados com Zod.
- Senha nunca retorna em response.
- JWT retorna no login.
- Usuário novo recebe avatar padrão.

## Critérios de aceite

- Testes de integração cobrem register/login.
- Erros têm formato consistente.
