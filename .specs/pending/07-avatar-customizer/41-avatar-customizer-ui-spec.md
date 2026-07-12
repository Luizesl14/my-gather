# 41 — Avatar Customizer UI Spec

## Objetivo

Criar tela de customização modular do avatar.

## MVP

Antes da customização modular completa, a criação de personagem deve funcionar em modo preset:

- carregar `web/assets/sprites/customization/avatar-creator.json`;
- listar os 8 personagens base;
- permitir escolher personagem;
- permitir definir nome de exibicao;
- permitir escolher pele, cabelo, cor do cabelo, rosto, barba/bigode, oculos, roupa superior, cor da roupa superior, roupa inferior, cor da roupa inferior, sapato, acessorios e cor de destaque;
- carregar swatches de `web/assets/sprites/customization`;
- salvar perfil granular com `characterId`, `skinToneId`, `hairStyleId`, `hairColorId`, `topId`, `topColorId`, `bottomId`, `bottomColorId`, `shoesId`, `accessoryIds` e `accentColorId`.

## Seções

- Preview.
- Pele.
- Cabelo.
- Rosto/olhos.
- Óculos/barba.
- Top.
- Bottom.
- Sapatos.
- Acessórios.

## Regras

- Preview usa mesmas camadas do mapa.
- Combinação inválida mostra fallback.
- Salvar persiste IDs de assets.

## Critérios de aceite

- Usuário altera visual.
- Preview atualiza.
- Customização reaparece após reload.
- No MVP, usuário consegue criar personagem a partir de preset mesmo sem camadas modulares prontas.
