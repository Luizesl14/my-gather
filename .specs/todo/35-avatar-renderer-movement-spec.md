# 35 — Avatar Renderer & Movement Spec

## Objetivo

Renderizar avatar local e controlar movimento.

## Criar

- `avatar_renderer.dart`
- `avatar_animation_controller.dart`
- input handler.
- collision checker.

## Movimento

- W/A/S/D.
- Setas.
- Clique para destino é fase posterior se pathfinding atrasar.

## Estados

- `idleFront`
- `idleBack`
- `idleLeft`
- `idleRight`
- `walkingUp`
- `walkingDown`
- `walkingLeft`
- `walkingRight`

## Critérios de aceite

- Avatar anda.
- Colisão local funciona.
- Sprite muda conforme direção.
