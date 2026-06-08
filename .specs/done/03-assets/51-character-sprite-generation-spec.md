# 51 — Character Sprite Generation Spec

## Objetivo

Definir exatamente quais personagens o projeto precisa, quais imagens devem ser criadas ou recortadas, quais poses são obrigatórias e como garantir consistência visual no estilo Gather-like pixel art.

Esta spec cobre apenas personagens/avatares. Tiles, móveis, balões, gestos e reações ficam nas specs `47` e `50`.

## Decisão

O projeto deve ter sprites finais de personagens para runtime. As imagens agrupadas em `images/` podem ser usadas como:

- referência visual;
- fonte de recorte;
- guia de proporção, pose e paleta.

Se os sprites finais não existirem, a implementação deve criar imagens recortadas ou gerar novas imagens consistentes com esta spec.

## Estilo obrigatório

- Pixel art 2D, estilo escritório virtual.
- Contorno escuro consistente.
- Cabeça levemente maior que corpo, visual amigável.
- Proporção compatível com tile `32x32`.
- Avatar base recomendado: `32x48` no MVP.
- Visual corporativo casual, não fantasia.
- Paleta compatível com light/dark mode.
- Personagens devem ser legíveis em zoom normal do mapa.

## Personagens MVP obrigatórios

Criar pelo menos 8 personagens base, cobrindo diversidade visual:

1. Homem cabelo castanho, roupa social azul.
2. Mulher cabelo preso, óculos, cardigan verde.
3. Homem pele escura, barba, camisa azul.
4. Mulher loira, blazer cinza/bege.
5. Pessoa cabelo preto, óculos, camisa branca.
6. Mulher pele média/escura, cabelo longo, roupa lilás.
7. Homem ruivo/barba, sweater verde.
8. Mulher cabelo preto preso, jaqueta escura.

Opcional para primeira expansão:

9. Pessoa mais velha, cabelo grisalho, camisa clara.
10. Pessoa com casaco bege, acessórios dourados.

## Poses obrigatórias por personagem

Cada personagem MVP precisa dos seguintes sprites:

```txt
idle-front.png
idle-back.png
idle-left.png
idle-right.png
walk-down-01.png
walk-down-02.png
walk-left-01.png
walk-left-02.png
walk-right-01.png
walk-right-02.png
walk-up-01.png
walk-up-02.png
```

## Estrutura de arquivos

```txt
web/assets/sprites/characters/
├── character-01/
│   ├── idle-front.png
│   ├── idle-back.png
│   ├── idle-left.png
│   ├── idle-right.png
│   ├── walk-down-01.png
│   ├── walk-down-02.png
│   ├── walk-left-01.png
│   ├── walk-left-02.png
│   ├── walk-right-01.png
│   ├── walk-right-02.png
│   ├── walk-up-01.png
│   └── walk-up-02.png
├── character-02/
└── character-08/
```

## Metadata obrigatória

Criar:

```txt
web/assets/sprites/characters/characters.json
```

Formato:

```json
{
  "version": 1,
  "tileSize": 32,
  "spriteSize": { "w": 32, "h": 48 },
  "characters": [
    {
      "id": "character-01",
      "displayName": "Default Male Blue Suit",
      "default": true,
      "frames": {
        "idleFront": "character-01/idle-front.png",
        "idleBack": "character-01/idle-back.png",
        "idleLeft": "character-01/idle-left.png",
        "idleRight": "character-01/idle-right.png",
        "walkDown": ["character-01/walk-down-01.png", "character-01/walk-down-02.png"],
        "walkLeft": ["character-01/walk-left-01.png", "character-01/walk-left-02.png"],
        "walkRight": ["character-01/walk-right-01.png", "character-01/walk-right-02.png"],
        "walkUp": ["character-01/walk-up-01.png", "character-01/walk-up-02.png"]
      },
      "hitbox": { "x": 6, "y": 22, "w": 20, "h": 24 }
    }
  ]
}
```

## Animação

- Idle: frame único por direção.
- Walk: 2 frames por direção.
- FPS padrão: `8fps`.
- Hitbox deve ficar nos pés/corpo, não na cabeça inteira.
- Nome e indicador de presença são overlays do renderer, não parte da imagem.

## Recorte de imagem agrupada

Se usar a imagem agrupada existente:

1. Identificar cada personagem e pose.
2. Recortar cada pose em PNG individual.
3. Normalizar canvas para `32x48` ou tamanho definido no metadata.
4. Preservar transparência.
5. Remover textos, números, labels e fundo quadriculado.
6. Salvar na estrutura de arquivos desta spec.
7. Atualizar `characters.json`.

## Geração de novos personagens

Se gerar novas imagens:

- Gerar em sprite sheet ou sprites individuais.
- Manter todos os personagens no mesmo estilo, escala e iluminação.
- Não misturar resolução, proporção ou perspectiva.
- Gerar sempre todas as poses obrigatórias.
- Evitar texto dentro da imagem.
- Fundo deve ser transparente.

Prompt base sugerido para geração:

```txt
Pixel art 2D office avatar sprite, Gather-like virtual office style, transparent background, consistent dark outline, friendly proportions, 32x48 sprite, corporate casual outfit, front/back/left/right idle and two walking frames per direction, clean readable character, no text, no labels.
```

## Customização futura

Para avatar modular, separar camadas:

- body/base;
- skin tone;
- hair back;
- face/eyes;
- facial hair;
- top clothing;
- bottom clothing;
- shoes;
- accessories;
- hair front.

No MVP, personagens fechados são aceitáveis. Customização modular pode vir depois, desde que o metadata permita migrar.

## Critérios de aceite

- Existem pelo menos 8 personagens base.
- Cada personagem tem 12 sprites obrigatórios.
- Todos os sprites têm fundo transparente.
- Todos os sprites têm tamanho consistente.
- `characters.json` referencia todos os arquivos.
- O renderer consegue carregar personagem padrão.
- Animação walking funciona nas 4 direções.
- Nenhum texto, label ou fundo quadriculado aparece no runtime.
- Personagens mantêm consistência visual com as imagens de referência em `images/`.
