# 50 — Sprite Slicing & Atlas Spec

## Objetivo

Definir como transformar as imagens agrupadas de `images/` em assets usáveis no web.

## Decisão

As imagens agrupadas podem e devem permanecer em `images/` como referência e fonte original. Para runtime, o app deve usar uma destas opções:

- sprites individuais recortados; ou
- sprite atlas com arquivo de metadata.

Não usar a imagem agrupada diretamente no renderer, porque isso acopla o código a coordenadas frágeis e dificulta animação, cache, colisão e troca de asset pack.

## Pastas

Fonte original:

- `images/`

Assets finais:

- `web/assets/sprites/characters/`
- `web/assets/sprites/customization/`
- `web/assets/sprites/gestures/`
- `web/assets/sprites/bubbles/`
- `web/assets/sprites/reactions/`
- `web/assets/tilesets/`
- `web/assets/furniture/`
- `web/assets/maps/`
- `web/assets/atlases/`

## Estratégia recomendada para avatar

Para MVP, usar sprites por personagem/pose:

```txt
web/assets/sprites/characters/default-male/idle-front.png
web/assets/sprites/characters/default-male/idle-back.png
web/assets/sprites/characters/default-male/idle-left.png
web/assets/sprites/characters/default-male/idle-right.png
web/assets/sprites/characters/default-male/walk-down-01.png
web/assets/sprites/characters/default-male/walk-down-02.png
web/assets/sprites/characters/default-male/walk-left-01.png
web/assets/sprites/characters/default-male/walk-left-02.png
web/assets/sprites/characters/default-male/walk-right-01.png
web/assets/sprites/characters/default-male/walk-right-02.png
web/assets/sprites/characters/default-male/walk-up-01.png
web/assets/sprites/characters/default-male/walk-up-02.png
```

Para customização futura, usar camadas modulares:

- corpo/base;
- pele;
- cabelo back;
- face/olhos;
- roupa superior;
- roupa inferior;
- sapatos;
- acessórios;
- cabelo front;
- overlay de gesto;
- overlay de balão.

## Estratégia recomendada para ícones e balões

Ícones de toolbar, gestos, reações e balões podem começar como sprites individuais:

```txt
web/assets/sprites/gestures/wave.png
web/assets/sprites/gestures/raise-hand.png
web/assets/sprites/reactions/coffee.png
web/assets/sprites/reactions/help.png
web/assets/sprites/bubbles/typing.png
web/assets/sprites/bubbles/call.png
```

Quando houver muitos assets, migrar para atlas:

```txt
web/assets/atlases/social-actions.png
web/assets/atlases/social-actions.json
```

## Metadata de atlas

Formato mínimo:

```json
{
  "image": "social-actions.png",
  "frames": {
    "gesture-wave": { "x": 0, "y": 0, "w": 32, "h": 32 },
    "bubble-typing": { "x": 32, "y": 0, "w": 32, "h": 32 }
  }
}
```

## Metadata de animação

Formato mínimo:

```json
{
  "animations": {
    "walkDown": {
      "fps": 8,
      "loop": true,
      "frames": ["walk-down-01", "walk-down-02"]
    },
    "wave": {
      "fps": 6,
      "loop": false,
      "durationMs": 2000,
      "frames": ["wave-01", "wave-02"]
    }
  }
}
```

## Critérios de aceite

- `images/` continua existindo como referência.
- Todo asset usado pelo app tem versão recortada ou entrada em atlas.
- Nenhum renderer usa coordenadas hardcoded de uma imagem agrupada original.
- Cada animação tem frames, fps, loop e duração documentados.
- Assets finais estão registrados no `pubspec.yaml`.
