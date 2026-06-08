# 24 — Workspace API & Map Spec

## Objetivo

Expor endpoints de workspace e mapa.

## Endpoints

- `POST /organizations/:organizationId/workspaces`
- `GET /organizations/:organizationId/workspaces`
- `GET /workspaces/:workspaceId`
- `GET /workspaces/:workspaceId/map`
- `GET /workspaces/:workspaceId/floors/:floorId`

## Response de mapa

Deve conter:

- workspace
- floor ativo
- map JSON
- rooms
- desks
- objects
- interactiveZones
- assetPackId

## Critérios de aceite

- Web consegue renderizar mapa só com esse payload.
- Response não expõe dados de outro workspace.
