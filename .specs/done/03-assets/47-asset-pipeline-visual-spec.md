# 47 — Asset Pipeline Visual Spec

## Objetivo

Organizar sprites, tilesets, móveis, ícones e versões.

## Pastas web

- `assets/sprites/characters/`
- `assets/sprites/customization/`
- `assets/sprites/gestures/`
- `assets/sprites/bubbles/`
- `assets/sprites/reactions/`
- `assets/tilesets/`
- `assets/furniture/`
- `assets/maps/`
- `assets/sounds/`

## Regras

- Nomes em kebab-case.
- Asset pack versionado.
- Collision mask documentada para objetos bloqueantes.
- Sprites mantêm contorno e proporção pixel art.
- Imagens agrupadas em `images/` são referência visual e fonte de recorte, não asset final de runtime.
- Runtime deve usar sprites individuais ou sprite atlas com metadata.
- Não depender de coordenadas manuais espalhadas no código para recortar imagens grandes.

## Critérios de aceite

- Assets registrados no `pubspec.yaml`.
- Mapa referencia assets existentes.
- Cada avatar, tile, móvel, gesto, reação e balão usado pelo app tem arquivo individual ou entrada em atlas documentada.
