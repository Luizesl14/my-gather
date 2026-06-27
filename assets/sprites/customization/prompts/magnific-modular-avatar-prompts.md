# Magnific Prompts For Modular Avatars

Use estes prompts para gerar camadas compatíveis com o contrato em
`assets/sprites/customization/modular-avatar-contract.json`.

## Regras Gerais

- Gerar uma categoria por vez: corpo, cabelo, roupa, acessorio.
- Aprovar `idle-front` antes de gerar outras direcoes.
- Fundo transparente; se o modelo gerar fundo, aplicar remove background.
- Personagem centralizado, corpo inteiro, sem sombra e sem objetos extras.
- Estilo: pixel art RPG top-down, escritorio virtual, legivel em `32x48`.
- Nao gerar personagem completo vestido quando o objetivo for uma camada.

## Corpo Base

```txt
Pixel art RPG avatar base body layer for a Gather-like virtual office.
Single neutral humanoid body only, no hair, no clothing, no shoes, no accessories.
Skin tone: {skinToneDescription}.
Pose: idle standing, facing {direction}.
Style: clean SNES/GBA-era pixel art, limited palette, crisp edges, no antialiasing.
Technical: full body centered, transparent background, no shadow, no text, no props.
Canvas/proportion target: readable after processing to 32x48 pixels, anchor at feet.
```

## Roupa Superior

```txt
Pixel art clothing overlay layer for the same 32x48 RPG avatar body.
Only the upper clothing item: {topDescription}.
No body, no head, no hair, no legs, no shoes, no background.
Pose alignment: idle standing, facing {direction}, matching a centered humanoid avatar.
Style: clean SNES/GBA-era pixel art, limited palette, crisp edges.
Transparent background. The layer must align over a 32x48 base body.
```

## Roupa Inferior

```txt
Pixel art clothing overlay layer for the same 32x48 RPG avatar body.
Only the lower clothing item: {bottomDescription}.
No torso, no head, no hair, no shoes, no background.
Pose alignment: idle standing, facing {direction}, matching a centered humanoid avatar.
Style: clean SNES/GBA-era pixel art, limited palette, crisp edges.
Transparent background. The layer must align over a 32x48 base body.
```

## Sapato

```txt
Pixel art shoe overlay layer for a 32x48 RPG avatar.
Only the shoes: {shoesDescription}.
No legs, no body, no head, no background.
Pose alignment: idle standing, facing {direction}, feet aligned to avatar anchor.
Style: clean SNES/GBA-era pixel art, limited palette, crisp edges.
Transparent background.
```

## Acessorio

```txt
Pixel art accessory overlay layer for a 32x48 RPG avatar.
Only the accessory: {accessoryDescription}.
No body, no clothing, no background.
Pose alignment: facing {direction}, aligned to a centered humanoid avatar.
Style: clean SNES/GBA-era pixel art, limited palette, crisp edges.
Transparent background.
```

## Primeiro Kit Recomendado

Para validar o fluxo sem gastar creditos demais:

1. `body-office-01`, idle front/back/left/right.
2. `top-shirt`, idle front/back/left/right.
3. `bottom-pants`, idle front/back/left/right.
4. `shoes-black`, idle front/back/left/right.
5. `accessory-badge`, idle front.

Depois que o renderer estiver correto, expandir para walk frames.
