# 34 — Office Canvas & Map Renderer Spec

## Objetivo

Renderizar escritório 2D em camadas.

## Criar

- `office_canvas.dart`
- `map_renderer.dart`
- `tile_renderer.dart`
- `object_renderer.dart`
- `interaction_renderer.dart`

## Ordem de camadas

1. Piso.
2. Tapetes.
3. Paredes.
4. Móveis inferiores.
5. Objetos interativos.
6. Avatares.
7. Móveis superiores.
8. Balões.
9. UI hints.

## Critérios de aceite

- Mapa JSON renderiza.
- Camadas não se sobrepõem errado.
- Dark mode mantém legibilidade.
