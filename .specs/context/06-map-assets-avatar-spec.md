# Map, Assets & Avatar Spec

## Mapa

Formato: JSON versionado.

Tile padrão: `32x32`.

Camadas:

```txt
Layer 0 — Base floor
Layer 1 — Carpet/decorative floor
Layer 2 — Walls/windows/doors
Layer 3 — Furniture bottom
Layer 4 — Interactive objects
Layer 5 — Avatars
Layer 6 — Furniture top/overlays
Layer 7 — Bubbles/reactions
Layer 8 — UI hints
```

## JSON mínimo de mapa

```json
{
  "id": "map-001",
  "version": 1,
  "width": 80,
  "height": 50,
  "tileSize": 32,
  "assetPackId": "office-default-v1",
  "layers": [
    {
      "name": "floor",
      "tiles": []
    },
    {
      "name": "walls",
      "tiles": []
    },
    {
      "name": "objects",
      "objects": []
    }
  ],
  "collision": [
    { "x": 0, "y": 0, "w": 80, "h": 1 }
  ],
  "interactiveZones": [
    {
      "id": "zone-room-alpha",
      "type": "enterRoom",
      "x": 10,
      "y": 8,
      "w": 3,
      "h": 2,
      "targetId": "room-alpha"
    }
  ]
}
```

## Regras de colisão

- Paredes, mesas, armários, plantas bloqueantes e portas fechadas bloqueiam avatar.
- Portas abertas podem remover ou reduzir colisão.
- O client valida colisão para resposta visual imediata.
- O backend valida posição crítica e impede trapaça.
- Collision mask pode ser retangular no MVP.
- Collision mask por sprite pode ficar para fase futura.

## Zonas interativas

Tipos MVP:

- `enterRoom`
- `leaveRoom`
- `sitAtDesk`
- `visitDesk`
- `openPanel`
- `useElevator`
- `openDoor`

Estados visuais:

- `hidden`: sem overlay.
- `nearby`: tracejado discreto.
- `focused`: tracejado com destaque.
- `disabled`: tracejado cinza.

## Asset packs

Asset pack padrão: `office-default-v1`.

Categorias:

- `CharacterSprite`
- `HairSprite`
- `ClothingSprite`
- `FurnitureSprite`
- `TileSprite`
- `WallSprite`
- `DoorSprite`
- `GestureIcon`
- `ReactionIcon`
- `BubbleSprite`

Campos mínimos:

```json
{
  "id": "asset-id",
  "type": "FurnitureSprite",
  "path": "assets/furniture/desks/wood-desk-01.png",
  "version": 1,
  "frameWidth": 64,
  "frameHeight": 64,
  "collision": { "x": 4, "y": 32, "w": 56, "h": 28 }
}
```

## Convenção de nomes

Arquivos:

- `characters/base/body-neutral-front.png`
- `characters/walk/walk-down-01.png`
- `customization/hair/hair-short-brown-front.png`
- `furniture/desks/desk-wood-left-01.png`
- `tiles/floor/wood-light-01.png`
- `bubbles/bubble-typing.png`
- `gestures/gesture-wave.png`
- `reactions/reaction-coffee.png`

IDs:

- kebab-case.
- Prefixo por categoria.
- Sufixo de versão quando necessário.

## Avatar

Camadas de renderização:

1. Base body.
2. Skin tone.
3. Hair back layer.
4. Face/eyes.
5. Facial hair.
6. Top clothing.
7. Bottom clothing.
8. Shoes.
9. Accessories.
10. Hair front layer.
11. Gesture overlay.
12. Bubble overlay.

Direções obrigatórias:

- `front`
- `back`
- `left`
- `right`

Estados obrigatórios:

- `idleFront`
- `idleBack`
- `idleLeft`
- `idleRight`
- `walkingUp`
- `walkingDown`
- `walkingLeft`
- `walkingRight`

Frames MVP:

- Idle: 1 frame por direção.
- Walk: 2 frames por direção.
- Gestos: overlay ou frame extra conforme asset.

## Customização MVP

Opções mínimas:

- 6 tons de pele.
- 8 estilos de cabelo.
- 10 cores de cabelo.
- 5 estilos de olhos/rosto.
- 6 tops.
- 6 bottoms.
- 6 sapatos.
- 6 acessórios.

Regras:

- Todas as combinações devem ser compatíveis com o corpo base.
- Acessórios incompatíveis devem ser filtrados.
- Perfil salvo deve referenciar IDs de assets, não caminhos diretos.
- Preview usa o mesmo renderer do avatar do mapa quando possível.

## Móveis e objetos MVP

Obrigatórios:

- Mesa individual.
- Cadeira.
- Mesa de reunião.
- Sofá.
- Planta.
- Armário.
- Quadro.
- Porta.
- Janela/vidro.
- Recepção.
- Cafeteira/área de copa.

Estados por objeto:

- `default`
- `interactive`
- `occupied`
- `disabled`
- `highlighted`

## Ícones, gestos e reações

Ícones obrigatórios:

- Chat.
- Typing.
- Voz.
- Chamar usuário.
- Convidar.
- Bater/knock.
- Sino.
- Pergunta.
- Alerta.
- Gritar.
- Ping.
- Acenar.
- Levantar mão.
- Apontar.
- Joinha.
- Café.
- Ajuda.
- Check.
- Celebração.
- Localização.
- Grupo.

## Pipeline de assets

No MVP:

- Assets ficam em `web/assets`.
- `pubspec.yaml` registra pastas.
- Backend referencia asset pack por ID e versão.

Futuro:

- Upload para storage.
- Versionamento no Asset Context.
- CDN.
- Migração de asset pack por workspace.

## Qualidade visual

- Sprites devem manter contorno escuro consistente.
- Não misturar perspectiva top-down com lateral fora do padrão.
- Objetos precisam respeitar proporção do tile.
- Avatares devem ficar acima do chão e abaixo de móveis superiores.
- Balões devem sempre ficar legíveis em light/dark.
