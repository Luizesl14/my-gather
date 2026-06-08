# Specs — Escritório Virtual Interativo

Esta pasta guarda a fila de implementação e os contratos de produto/arquitetura do projeto.

## Como navegar

1. Leia `00-implementation-sequence-spec.md` para saber a ordem das atividades.
2. Use `context/` quando precisar entender produto, domínio, UI, realtime, assets ou testes.
3. Pegue a próxima spec em `todo/` quando for implementar algo novo.
4. Consulte `pending/` para trabalhos parcialmente feitos que ainda faltam critério de aceite.
5. Consulte `done/` apenas para histórico do que já foi concluído.

## Estrutura

- `00-implementation-sequence-spec.md`: fila operacional principal.
- `context/`: specs amplas de referência, usadas por várias fases.
- `todo/`: specs granulares ainda não concluídas.
- `pending/`: atividades parcialmente feitas, mas ainda não aceitas como concluídas.
- `done/`: atividades e specs finalizadas, separadas por fase.

## Fases em `done`

- `done/00-preparacao/`: estrutura inicial, documentação e env examples.
- `done/01-infra/`: Docker Compose e healthcheck local.
- `done/02-backend/`: scaffold backend, DDD shared, módulos, config e WebSocket base.
- `done/03-web/`: scaffold Flutter Web, arquitetura base e design system.
- `done/03-assets/`: asset pack, personagens, tiles, móveis e sprites sociais.
- `done/04-identity/`: domínio, use cases e REST Identity.
- `done/05-workspace/`: domínio Workspace, mapa mockado, endpoints de mapa e renderer estático.
- `done/06-avatar/`: catálogo do avatar, renderer local e movimento por teclado.

## Regra de status

- Move para `done/` somente quando os critérios de aceite foram validados.
- Move para `pending/` quando existe implementação parcial, mas falta validação ou algum critério.
- Mantém em `todo/` enquanto ainda não foi executado.
- Mantém em `context/` quando a spec é referência viva para mais de uma fase.

## Guardrails

- Documentar em português.
- Seguir DDD, Clean Architecture e separação entre domínio, aplicação, infraestrutura e apresentação.
- UI deve seguir `context/02-theme-layout-spec.md`.
- Componentes visuais devem seguir `context/03-component-animation-spec.md`.
- Eventos realtime e APIs devem ser documentados antes de implementação.
- Regras de negócio não devem ficar em controllers, widgets ou renderizadores.
