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

---

## Status (2026-07-12) — parcialmente implementado, em pending

### Entregue
- Tela `/character/custom` (`web/lib/features/avatar/presentation/avatar_customizer_page.dart`), acessível pelo botão "Criar personagem" na seleção de personagem.
- Sistema modular real (superou o MVP preset): camadas geradas via Kling sobre corpo base único, catálogo data-driven em `web/assets/sprites/customization/modular/modular-catalog.json`.
- Slots funcionando: corpo, calça (2), sapato (1), roupa (3), barba (1), cabelo (2).
- Cores por palette swap em runtime (cabelo, roupa, calça) — recolor por luminância no `ModularAvatarBaker`; swatches na UI.
- Preview animado com as mesmas camadas do jogo (frames assados, 4 direções, walk cycle).
- Persistência: loadout serializado em id `custom:body=...;hair=...;hairC=...` salvo via PUT /auth/me/avatar; restaurado no login (characterProvider + avatarLoadoutProvider).
- Renderização no office para avatar próprio e remotos (`AvatarSceneLoader.resolveCharacter` + baker); miniaturas em dock/chat/chamada (`AvatarThumbnail`).
- Testes: roundtrip do loadout e parse/ordenação do catálogo (12 testes).

### Falta para aceitar como done
- Tom de pele (recolor restrito à faixa de matiz de pele do corpo).
- Rosto/olhos, óculos e acessórios (sem assets gerados ainda; região `glasses` já existe no extrator `scripts/extract_kling_overlay.py`).
- Cor de destaque (accent) e nome de exibição na tela.
- Fallback visual explícito para combinação inválida (hoje camada ausente simplesmente não desenha).
- Validação do usuário: caminhada nas 4 direções com a arte v3.

### Referências de pipeline
- Geração/fatiamento: `scripts/kling_sheet_to_frames.py`; extração de camada: `scripts/extract_kling_overlay.py`.
- Fontes: `assets/kling/raw/` (sheets Kling), `assets/kling/frames/` (frames e overlays).
