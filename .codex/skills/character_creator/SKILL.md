---
name: character_creator
description: Pipeline completo para criar sprites pixel art de personagens usando Magnific MCP. Use quando o usuario quiser criar um novo personagem para o jogo a partir de uma foto de pessoa ou descricao. Gera todos os 16 frames necessarios (4 idle + 12 walk), remove fundo, redimensiona e atualiza o catalogo do jogo automaticamente.
---

# Character Creator — Pipeline Completo

## Objetivo

Criar um personagem jogavel completo para o Love+Robot a partir de:
- Uma foto de pessoa em `images/person/` como referencia de aparencia
- Ou uma descricao textual do personagem
- Estilo visual definido pelas referencias em `images/trae/`

## Personagens existentes

Characters 01-06 ja existem:
- character-01: Carla
- character-02: Matt
- character-03: Morena
- character-04: Nakma
- character-05: Robbit
- character-06: Young

Novo personagem começa em `character-07`.

## Frames necessarios por personagem

```
web/assets/sprites/characters/character-07/
  idle-front.png      ← personagem de frente, parado
  idle-back.png       ← personagem de costas, parado
  idle-left.png       ← personagem virado para esquerda, parado
  idle-right.png      ← personagem virado para direita, parado
  walk-down-01.png    ← andando em direcao a camera, perna direita a frente
  walk-down-02.png    ← andando em direcao a camera, pos neutro
  walk-down-03.png    ← andando em direcao a camera, perna esquerda a frente
  walk-left-01.png    ← andando para esquerda, frame 1
  walk-left-02.png    ← andando para esquerda, frame 2
  walk-left-03.png    ← andando para esquerda, frame 3
  walk-right-01.png   ← andando para direita, frame 1
  walk-right-02.png   ← andando para direita, frame 2
  walk-right-03.png   ← andando para direita, frame 3
  walk-up-01.png      ← andando se afastando da camera, frame 1
  walk-up-02.png      ← andando se afastando, frame 2
  walk-up-03.png      ← andando se afastando, frame 3
  preview.png         ← frame idle-front redimensionado para 128x192 (thumb)
```

## Pipeline de Geracao

### ETAPA 1 — Upload das referencias locais

Faca o upload dos arquivos de referencia de estilo e da pessoa. Carregue todos em batch:

```
# Upload das 3 referencias de estilo (avatar-modular-sheet-style-ref v1, v2, v3)
1. creations_request_upload (mimeType: image/png, count: 3)
2. curl -T <arquivo> <put_url> para cada um
3. creations_finalize_upload (uploads: [path1, path2, path3])
   → Guarde: styleRef1, styleRef2, styleRef3

# Upload da foto da pessoa (ex: images/person/carla.png)
4. creations_request_upload (mimeType: image/png, count: 1)
5. curl -T <pessoa.png> <put_url>
6. creations_finalize_upload (path: <path>)
   → Guarde: personRef
```

### ETAPA 2 — Gerar personagem base (idle-front)

Gere o frame base do personagem de frente. Este sera a referencia visual para todos os outros frames.

**Prompt para idle-front:**
```
Pixel art RPG character sprite, 2D top-down perspective, single character idle standing pose facing forward (toward camera).
Character appearance: [DESCREVER aparencia baseada na foto de referencia — cor de cabelo, pele, roupas].
Style: SNES/GBA-era RPG pixel art, clean silhouette, limited palette 16-32 colors, no anti-aliasing.
Framing: full body from head to feet, centered, no background, transparent.
Size reference: proportional to 32x48 pixel grid (head ~8px, body ~16px, legs ~16px tall, 24px wide).
Pose: neutral standing, arms slightly relaxed at sides, feet together.
No shadow, no background, no text, no extra objects.
```

**Chamada MCP:**
```json
{
  "prompt": "<prompt acima + descricao especifica do personagem>",
  "aspectRatio": "2:3",
  "references": [
    { "type": "image", "identifier": "<personRef>" },
    { "type": "style", "identifier": "<styleRef1>" },
    { "type": "style", "identifier": "<styleRef2>" },
    { "type": "style", "identifier": "<styleRef3>" }
  ],
  "count": 2
}
```

Gere 2 variacoes e escolha a melhor antes de continuar.

### ETAPA 3 — Remover fundo do base

```json
images_remove_background({ "creationIdentifier": "<idle-front-approved>" })
```
→ Guarde: `idleFrontNoBg`

### ETAPA 4 — Gerar demais idle frames (back, left, right)

Para cada direcao, use o frame aprovado como referencia + as mesmas referencias de estilo:

**idle-back prompt:**
```
Pixel art RPG character sprite, same character as reference image but viewed from behind (camera behind character, walking away).
Same style, same clothing, same color palette as reference. Facing away from camera.
Full body, centered, no background, transparent, 2:3 proportions.
```

**idle-left prompt:**
```
Pixel art RPG character sprite, same character as reference image viewed from the left side (character's right, profile view).
Same style, clothing, colors. Side profile, full body, centered, no background, transparent, 2:3 proportions.
```

**idle-right prompt:**
```
Pixel art RPG character sprite, same character as reference image viewed from the right side (character's left, profile view, mirrored from left view).
Same style, clothing, colors. Side profile facing right, full body, no background, transparent, 2:3 proportions.
```

**Chamada MCP para cada direcao:**
```json
{
  "prompt": "<prompt de direcao>",
  "aspectRatio": "2:3",
  "references": [
    { "type": "image", "identifier": "<idleFrontNoBg>" },
    { "type": "style", "identifier": "<styleRef1>" },
    { "type": "style", "identifier": "<styleRef2>" }
  ],
  "count": 2
}
```

Remova o fundo de cada um com `images_remove_background`.

### ETAPA 5 — Gerar frames de walk (down)

3 frames simulando ciclo de caminhada em direcao a camera:

**walk-down-01 prompt:**
```
Pixel art RPG character sprite walking toward camera, step 1: right leg forward, left leg back, mid-stride.
Same character as reference. Full body, no background, transparent, 2:3 proportions. Slightly lower arms swung in opposite direction to legs.
```

**walk-down-02 prompt:**
```
Pixel art RPG character sprite walking toward camera, step 2: neutral passing position, both feet closer together, body upright.
Same character as reference. Full body, no background, transparent, 2:3 proportions.
```

**walk-down-03 prompt:**
```
Pixel art RPG character sprite walking toward camera, step 3: left leg forward, right leg back, completing stride.
Same character as reference. Full body, no background, transparent, 2:3 proportions.
```

### ETAPA 6 — Gerar frames de walk (up/left/right)

Repita o mesmo padrao de 3 frames para cada direcao:
- **walk-up**: Character caminhando se afastando da camera (de costas)
- **walk-left**: Character caminhando para a esquerda (perfil)
- **walk-right**: Character caminhando para a direita (perfil espelhado)

Para walk-right, pode usar `images_generate` com prompt "mirror image" ou gerar um novo conjunto.

### ETAPA 7 — Redimensionar para 32x48

Para cada frame aprovado (background ja removido), use `images_resize`:

```json
images_resize({
  "creationIdentifier": "<frame-no-bg>",
  "width": 32,
  "height": 48
})
```

**Faça isso para todos os 16 frames.**

### ETAPA 8 — Download, processar e salvar no projeto

Para cada frame aprovado (background ja removido), obtenha a URL de download via `creations_show` ou `creations_get`.

**Fluxo por frame:**

```bash
# 1. Baixar o PNG do Magnific (ainda grande, ex: 512x768 ou 2048x3072)
CHAR=character-07
TMP="images/downloads/$CHAR"
mkdir -p "$TMP"
curl -o "$TMP/idle-front-raw.png" "<download_url>"

# 2. Processar: remover fundo restante + normalizar + redimensionar para 32x48
python3 scripts/process_character_frame.py \
  "$TMP/idle-front-raw.png" \
  "web/assets/sprites/characters/$CHAR/idle-front.png"
```

Repita para todos os 16 frames. O script `process_character_frame.py` ja faz:
- Remocao de fundo checkerboard
- Crop no bounding box do personagem
- Centralizacao em canvas 96x144
- Resize para 32x48 com nearest-neighbor (pixel-perfect)

### ETAPA 9 — Registrar no catalogo

Depois que todos os 16 frames estiverem prontos, rode:

```bash
python3 scripts/register_character.py \
  --id character-07 \
  --name "Alice" \
  --description "Alice do time de marketing"
```

O script automaticamente:
- Gera o `preview.png` (128x192) a partir do `idle-front.png`
- Atualiza `web/assets/sprites/characters/characters.json`
- Adiciona a entrada em `web/pubspec.yaml`

## Estrategia de Creditos

- **Nao gere todos os 16 frames de uma vez.** Aprove o `idle-front` antes de continuar.
- Gere o `idle-back` depois de aprovar front. Gere `idle-left` e use `images_variations` com `angles` para obter `idle-right`.
- Para walk frames: gere `walk-down` primeiro. Se o estilo estiver bom, gere os outros.
- Limite `count` a 2 em cada chamada. Escolha um antes de fazer mais.
- Use `images_remove_background` apenas em imagens aprovadas.
- Use `images_resize` apenas apos fundo removido.

## Referencias de estilo disponiveis

```
images/trae/avatar-customization-kit-v1.png          ← customizacao de personagem
images/trae/avatar-customization-kit-v2-safe.png     ← variante segura do kit
images/trae/avatar-modular-sheet-style-ref-v1.png    ← folha de sprites modular (PRINCIPAL)
images/trae/avatar-modular-sheet-style-ref-v2.png    ← variante
images/trae/avatar-modular-sheet-style-ref-v3.png    ← variante
```

## Referencias de pessoa disponiveis

```
images/person/carla.png   → character-01
images/person/matt.png    → character-02
images/person/morena.png  → character-03
images/person/nakma.png   → character-04
images/person/robbit.png  → character-05
images/person/young.png   → character-06
```

Para novos personagens, o usuario deve fornecer a foto da pessoa.

## Upload de arquivos locais — sequencia correta

```
1. creations_request_upload (mimeType: "image/png", count: 1)
   → retorna: { uploads: [{ uploadUrl, path }] }

2. Bash: curl -T <arquivo_local> "<uploadUrl>"

3. creations_finalize_upload (path: "<path>")
   → retorna: { identifier } ← use como creationIdentifier
```

## Checkpoint apos geracao

Antes de fazer download e salvar no projeto, confirme com o usuario:
1. Mostre preview de todos os 16 frames via `creations_show`
2. Pergunte se aprova o conjunto completo
3. So entao execute as ETAPAs 8-10
