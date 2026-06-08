#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "docker não encontrado" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose não encontrado" >&2
  exit 1
fi

if ! docker compose ps -q postgres >/dev/null 2>&1; then
  echo "serviço postgres não encontrado no docker compose" >&2
  exit 1
fi

if ! docker compose ps -q redis >/dev/null 2>&1; then
  echo "serviço redis não encontrado no docker compose" >&2
  exit 1
fi

docker compose exec -T postgres pg_isready -U postgres -d love_robot >/dev/null

if ! docker compose exec -T redis redis-cli ping | grep -q "PONG"; then
  echo "redis indisponível" >&2
  exit 1
fi

echo "infra ok"
