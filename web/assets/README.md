# Assets iniciais

Assets gerados a partir das imagens agrupadas em `images/`.

## Gerar novamente

```sh
python scripts/generate_initial_assets.py
```

## Pronto agora

- `sprites/characters/characters.json`
- `sprites/customization/avatar-creator.json`
- swatches de customizacao:
  - `sprites/customization/skin-tones/`
  - `sprites/customization/hair-colors/`
  - `sprites/customization/clothing-colors/`
  - `sprites/customization/accent-colors/`
- opcoes granulares no avatar creator:
  - pele
  - cabelo
  - cor do cabelo
  - rosto
  - barba/bigode
  - oculos
  - roupa superior
  - cor da roupa superior
  - roupa inferior
  - cor da roupa inferior
  - sapato
  - acessorios
  - cor de destaque
- 10 personagens base em `sprites/characters/character-01` a `character-10`
- 12 sprites por personagem:
  - idle front/back/left/right
  - walk down/left/right/up com 2 frames por direção
- sprites sociais mínimos:
  - `sprites/bubbles/chat.png`
  - `sprites/bubbles/typing.png`
  - `sprites/bubbles/call.png`
  - `sprites/bubbles/knock.png`
  - `sprites/bubbles/shout.png`
  - `sprites/gestures/wave.png`
  - `sprites/reactions/coffee.png`
  - `sprites/reactions/help.png`
- tiles mínimos em `tilesets/`
- móveis mínimos em `furniture/`
- atlas social em `atlases/social-actions.png`
- mapa inicial em `maps/office-default.json`
- manifest do asset pack em `asset-pack.json`
- `components/components.json`

## Regra

As imagens em `images/` continuam como fonte original e referência visual. O app deve consumir os sprites finais em `web/assets`, não as imagens agrupadas.
