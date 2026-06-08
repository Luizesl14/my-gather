# 43 — Avatar Animation Spec

## Objetivo

Detalhar animações de avatar.

## Idle

- 1 frame por direção.
- Blink opcional a cada `4s-7s`.

## Walk

- 2 frames por direção.
- `8fps`.
- Direção atual define sprite.

## Remoto

- Interpolação máxima `120ms`.
- Delta acima de `3 tiles`: snap com fade `80ms`.

## Receber interação

- Chamada: pulse `3 vezes / 900ms`.
- Gesto: overlay por duração definida.

## Critérios de aceite

- Movimento não treme.
- Avatar remoto não salta em updates normais.
