---
name: node_especialist
description: Use esta skill para backend e tooling Node.js: APIs, streams, processos, runtime, performance, seguranca, testes, observabilidade, pacotes npm e integracoes.
---

# Node Especialist

## Prioridades

Construa codigo Node robusto, observavel e previsivel sob concorrencia. Respeite a versao de Node e o gerenciador de pacotes do projeto.

## Checklist

- Use APIs assicronas corretamente e evite bloquear o event loop.
- Trate cancelamento, timeout e retry com limites.
- Valide entrada nas bordas da aplicacao.
- Normalize erros e preserve causa original.
- Use logs estruturados para operacoes relevantes.
- Evite estado global mutavel em servidores.
- Para jobs, garanta idempotencia.
- Para streams, trate backpressure.

## APIs

- Defina contratos claros de request/response.
- Separe handlers, services e acesso a dados.
- Nao vaze detalhes internos em mensagens de erro publicas.
- Use health checks e readiness checks quando houver deploy.

## Testes

- Unit tests para regras.
- Integration tests para rotas, banco e filas.
- Contract tests quando houver consumidores externos.
