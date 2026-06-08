# ADR — Love+Robot

## Objetivo

Registrar decisões arquiteturais relevantes e seus trade-offs.

## Escopo

- Estrutura do monorepo.
- DDD/Hexagonal no backend.
- Estratégia de realtime (WebSocket + eventos).
- Estratégia de renderização do mapa e avatares no Flutter.

## Referências

- `.specs/done/00-preparacao/10-monorepo-structure-spec.md`
- `.specs/context/04-ddd-domain-spec.md`
- `.specs/context/05-api-realtime-spec.md`

## ADR-006 — Movimento local por teclado, clique adiado

Data: 2026-06-04

Decisão:

- Implementar movimento local do avatar por teclado com validação de colisão no cliente.
- Adiar movimento por clique até a fase de navegação/pathfinding.

Trade-off:

- Mantém a interação mínima funcional sem introduzir algoritmo de rota prematuro.
- Evita acoplar o renderer local a uma heurística incompleta de caminho.
