# 08 — Asset Prerequisites Spec

## Objetivo

Definir os assets que precisam existir antes de implementar renderer, movimento, mapa, avatar e UI social.

Esta spec corrige a ordem de execução: assets finais de runtime são pré-requisito do web visual. As specs detalhadas continuam existindo:

- `47-asset-pipeline-visual-spec.md`
- `50-sprite-slicing-atlas-spec.md`
- `51-character-sprite-generation-spec.md`

## Ordem correta antes do web visual

Antes de executar:

- `34-office-canvas-map-renderer-spec.md`
- `35-avatar-renderer-movement-spec.md`
- `36-remote-presence-ui-spec.md`
- `37-desk-ui-interaction-spec.md`
- `38-room-ui-meeting-spec.md`
- `40-toolbar-actions-spec.md`
- `43-avatar-animation-spec.md`
- `44-bubble-animation-spec.md`
- `45-gesture-reaction-animation-spec.md`

Executar primeiro:

1. Definir asset pack inicial.
2. Recortar ou gerar personagens MVP.
3. Recortar ou gerar tiles básicos.
4. Recortar ou gerar móveis básicos.
5. Recortar ou gerar ícones, gestos, reações e balões.
6. Criar metadata de personagens e atlas.
7. Registrar assets no `pubspec.yaml`.
8. Criar mapa mockado que referencia assets existentes.

## Assets mínimos para o app rodar

### Personagens

- Pelo menos 1 personagem padrão para primeira execução.
- Pelo menos 8 personagens para fechar MVP.
- Cada personagem com 12 sprites:
  - `idle-front`
  - `idle-back`
  - `idle-left`
  - `idle-right`
  - `walk-down-01`
  - `walk-down-02`
  - `walk-left-01`
  - `walk-left-02`
  - `walk-right-01`
  - `walk-right-02`
  - `walk-up-01`
  - `walk-up-02`

### Mapa

- Piso padrão.
- Parede padrão.
- Porta.
- Janela/vidro.
- Tapete.
- Zona interativa.

### Móveis

- Mesa individual.
- Cadeira.
- Mesa de reunião.
- Planta.
- Sofá.
- Armário.

### Social UI

- Balão typing.
- Balão call.
- Balão knock.
- Balão coffee.
- Ícone wave.
- Ícone shout.
- Ícone help.
- Ícone chat.

## Critério de aceite

- O app consegue renderizar o escritório inicial com mapa, pelo menos um avatar, mesa, sala e balão typing.
- Nenhum renderer depende diretamente das imagens agrupadas em `images/`.
- Todo asset usado tem arquivo recortado ou entrada em atlas com metadata.
