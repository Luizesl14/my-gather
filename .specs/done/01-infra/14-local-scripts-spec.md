# 14 — Local Scripts Spec

## Objetivo

Criar scripts locais para validar infra e facilitar execução.

## Criar

- `scripts/check-infra.sh`
- `scripts/dev-backend.sh`
- `scripts/dev-web.sh`
- `scripts/test-all.sh`

## Regras

- Scripts devem falhar com exit code diferente de zero em erro.
- Scripts devem ser pequenos e legíveis.
- Não embutir segredos.

## Critérios de aceite

- `check-infra.sh` valida Postgres e Redis.
- `test-all.sh` chama testes backend e web quando existirem.
