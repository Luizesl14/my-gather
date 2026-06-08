# 23 — Workspace Domain Spec

## Objetivo

Implementar domínio de escritório, andar, mapa, salas, mesas e zonas.

## Agregados

- `WorkspaceAggregate`
- `FloorAggregate`
- `RoomAggregate`
- `DeskAggregate`

## Regras

- Workspace pertence a organização.
- Floor pertence a workspace.
- Mapa tem tamanho, tileSize, layers, collision e zones.
- Sala deve estar dentro do mapa.
- Mesa deve estar dentro do mapa.
- Objeto bloqueante gera colisão.

## Eventos

- `WorkspaceCreated`
- `FloorCreated`
- `MapPublished`
- `RoomCreated`
- `DeskAssigned`

## Critérios de aceite

- Testes impedem sala/mesa fora do mapa.
- Mapa publicado precisa ser válido.
