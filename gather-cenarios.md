# Gather-like Scenarios in Flutter

Este documento descreve como implementar, em Flutter, uma experiencia parecida com Gather/Gather.town: mapas 2D em tiles, personagens navegaveis, objetos interativos, areas privadas e comunicacao por proximidade.

O Gather real nao tem o codigo principal aberto publicamente. As partes abaixo combinam informacoes publicas da documentacao do Gather com uma arquitetura propria para Flutter.

Fontes publicas relevantes:

- Gather Mapmaker Overview: https://support.gather.town/articles/9657827678-mapmaker-overview
- Gather Tile Effects Overview: https://support.gather.town/articles/3805539818-tile-effects-overview
- Gather Sizes: https://support.gather.town/articles/9253868124-sizes
- Gather API: https://support.gather.town/articles/9786368425-gather-api
- API examples: https://github.com/gathertown/api-examples
- WorkAdventure, alternativa open source similar: https://github.com/workadventure/workadventure

## Objetivo

Criar um sistema de cenarios 2D em Flutter com:

- Mapa baseado em grid de tiles.
- Camadas de renderizacao: background, objetos, personagens e foreground.
- Personagens animados com movimento em quatro direcoes.
- Colisao por tile.
- Objetos interativos.
- Areas especiais, como spawn, private area e spotlight.
- Multiplayer em tempo real.
- Audio/video por proximidade.
- Editor ou importador de mapas.

## Premissas Tecnicas

O Gather usa mapas 2D baseados em tiles. A documentacao publica indica tiles de 32x32 px e personagens pequenos, na faixa de 30-36 px.

Para Flutter, a implementacao recomendada e usar:

- `flame` para motor 2D.
- `flame_tiled` para importar mapas `.tmx` criados no Tiled Map Editor.
- `flutter_webrtc` ou LiveKit para audio/video.
- WebSocket para sincronizacao de posicao e estado dos jogadores.
- Backend proprio para salas, usuarios, mapas e presenca.

Pacotes sugeridos:

```yaml
dependencies:
  flame: ^1.18.0
  flame_tiled: ^1.20.0
  flutter_webrtc: ^0.11.0
  web_socket_channel: ^3.0.0
  equatable: ^2.0.5
  uuid: ^4.4.0
```

As versoes devem ser conferidas antes da instalacao, pois podem mudar.

## Modelo Mental do Mapa

Um cenario e uma sala 2D. Cada sala contem:

- `background`: camada visual inferior.
- `collision`: camada invisivel com tiles bloqueados.
- `objects`: objetos visuais e interativos.
- `zones`: areas logicas invisiveis.
- `foreground`: camada visual superior.
- `spawnPoints`: pontos onde personagens aparecem.

Em Flutter/Flame, isso pode ser representado como:

```dart
class Scenario {
  final String id;
  final String name;
  final int tileSize;
  final int widthInTiles;
  final int heightInTiles;
  final List<MapLayer> layers;
  final List<ScenarioObject> objects;
  final List<TileZone> zones;
  final List<SpawnPoint> spawnPoints;

  const Scenario({
    required this.id,
    required this.name,
    this.tileSize = 32,
    required this.widthInTiles,
    required this.heightInTiles,
    required this.layers,
    required this.objects,
    required this.zones,
    required this.spawnPoints,
  });
}
```

## Tiles

O tile e a menor unidade navegavel do mapa.

Recomendacao:

- Usar `32x32 px` como base.
- Salvar posicoes logicas em coordenadas de tile.
- Renderizar em pixels multiplicando por `tileSize`.
- Permitir posicao interpolada para animacao suave.

Exemplo:

```dart
class TileCoord {
  final int x;
  final int y;

  const TileCoord(this.x, this.y);

  Vector2 toWorld({int tileSize = 32}) {
    return Vector2(x * tileSize.toDouble(), y * tileSize.toDouble());
  }
}
```

## Camadas de Renderizacao

A ordem recomendada de desenho e:

1. Background.
2. Tiles decorativos inferiores.
3. Objetos baixos.
4. Personagens e objetos ordenados por eixo Y.
5. Foreground.
6. UI local.

Essa ordenacao por `y` simula profundidade: um personagem na parte inferior da tela aparece na frente de objetos/personagens acima.

Em Flame, isso pode ser feito com `priority`:

```dart
component.priority = component.position.y.toInt();
```

Para camadas fixas:

```dart
class RenderPriority {
  static const background = 0;
  static const floorObjects = 100;
  static const dynamicEntities = 1000;
  static const foreground = 100000;
  static const ui = 200000;
}
```

Personagens e objetos dinamicos devem atualizar a prioridade conforme a posicao muda.

## Background

O background pode ser:

- Um tilemap importado do Tiled.
- Uma imagem unica grande.
- Uma combinacao de tiles e imagem base.

Para cenarios editaveis, prefira tilemap. Para cenarios desenhados/artisticos, uma imagem unica pode ser mais simples.

Recomendacao pratica:

- Usar Tiled para montar mapas `.tmx`.
- Separar tilesets por tema: escritorio, casa, escola, evento, externo.
- Exportar camadas com nomes padronizados.

Nomes de camadas sugeridos:

- `background`
- `floor`
- `walls`
- `objects_low`
- `objects_high`
- `collision`
- `zones`
- `foreground`

## Foreground

Foreground e usado para elementos que devem aparecer acima do personagem:

- Topo de paredes.
- Arvores.
- Portas altas.
- Letreiros.
- Partes superiores de moveis.

Exemplo: se uma arvore ocupa dois tiles de altura, o tronco pode ficar em `objects_low` e a copa em `foreground`.

## Colisao

Colisao deve ser resolvida no grid.

Um tile bloqueado impede que o personagem entre nele.

Tipos comuns:

```dart
enum TileCollision {
  none,
  blocked,
}
```

Modelo:

```dart
class CollisionMap {
  final int width;
  final int height;
  final Set<TileCoord> blockedTiles;

  const CollisionMap({
    required this.width,
    required this.height,
    required this.blockedTiles,
  });

  bool isBlocked(TileCoord coord) {
    if (coord.x < 0 || coord.y < 0) return true;
    if (coord.x >= width || coord.y >= height) return true;
    return blockedTiles.contains(coord);
  }
}
```

Fluxo de movimento:

1. Jogador pressiona direcao.
2. Sistema calcula o tile de destino.
3. Verifica se o tile esta bloqueado.
4. Se livre, inicia interpolacao ate o destino.
5. Ao concluir, atualiza posicao logica.
6. Envia nova posicao ao servidor.

## Movimento do Personagem

O personagem deve ter:

- `id`
- `displayName`
- `avatar`
- `currentTile`
- `targetTile`
- `direction`
- `movementState`
- `animationState`

```dart
enum Direction {
  up,
  down,
  left,
  right,
}

enum MovementState {
  idle,
  walking,
}

class PlayerState {
  final String id;
  final String displayName;
  final TileCoord currentTile;
  final TileCoord? targetTile;
  final Direction direction;
  final MovementState movementState;

  const PlayerState({
    required this.id,
    required this.displayName,
    required this.currentTile,
    required this.targetTile,
    required this.direction,
    required this.movementState,
  });
}
```

O deslocamento visual deve ser interpolado:

```dart
Vector2 lerpPosition(Vector2 from, Vector2 to, double progress) {
  return from + (to - from) * progress.clamp(0, 1);
}
```

## Sprites dos Personagens

Personagens podem usar spritesheets com linhas por direcao.

Formato sugerido:

- Frame size: `32x32` ou `48x48`.
- Linha 0: andando para baixo.
- Linha 1: andando para esquerda.
- Linha 2: andando para direita.
- Linha 3: andando para cima.
- 3 ou 4 frames por animacao.

Mesmo que o Gather use personagens pequenos, em Flutter e comum usar sprites de `32x32` ou `48x48`, mantendo o pe do personagem alinhado ao tile atual.

Ponto importante: a posicao logica do personagem deve representar o pe/base, nao o centro visual do sprite.

## Objetos

Objetos sao entidades posicionadas no mapa.

Tipos:

- Decorativo.
- Colisivel.
- Interativo.
- Link externo.
- Video/embed.
- Portal.
- Whiteboard.
- Mesa privada.
- NPC.

Modelo:

```dart
enum ScenarioObjectType {
  decorative,
  interactive,
  portal,
  embeddedMedia,
  npc,
}

class ScenarioObject {
  final String id;
  final ScenarioObjectType type;
  final String name;
  final TileCoord tile;
  final int widthInTiles;
  final int heightInTiles;
  final bool blocksMovement;
  final Interaction? interaction;

  const ScenarioObject({
    required this.id,
    required this.type,
    required this.name,
    required this.tile,
    required this.widthInTiles,
    required this.heightInTiles,
    this.blocksMovement = false,
    this.interaction,
  });
}
```

Interacao:

```dart
enum InteractionType {
  openUrl,
  openModal,
  startCall,
  teleport,
  showMessage,
}

class Interaction {
  final InteractionType type;
  final Map<String, dynamic> payload;

  const Interaction({
    required this.type,
    required this.payload,
  });
}
```

## Deteccao de Interacao

Um objeto fica interativo quando:

- O jogador esta no mesmo tile.
- O jogador esta adjacente ao objeto.
- O jogador esta dentro de uma area de alcance.

Recomendacao:

- Usar distancia Manhattan para grid.
- Mostrar prompt discreto quando houver interacao disponivel.

```dart
int manhattanDistance(TileCoord a, TileCoord b) {
  return (a.x - b.x).abs() + (a.y - b.y).abs();
}

bool canInteract(TileCoord player, ScenarioObject object) {
  return manhattanDistance(player, object.tile) <= 1;
}
```

## Tile Effects

Inspirado na documentacao publica do Gather, o sistema deve suportar efeitos de tile.

Tipos sugeridos:

```dart
enum TileEffectType {
  impassable,
  spawn,
  privateArea,
  spotlight,
  portal,
  silentArea,
}
```

Modelo:

```dart
class TileZone {
  final String id;
  final TileEffectType type;
  final Set<TileCoord> tiles;
  final Map<String, dynamic> metadata;

  const TileZone({
    required this.id,
    required this.type,
    required this.tiles,
    this.metadata = const {},
  });

  bool contains(TileCoord coord) {
    return tiles.contains(coord);
  }
}
```

## Areas Privadas

Uma private area isola conversa por grupo.

Regras:

- Jogadores dentro da mesma private area se escutam.
- Jogadores fora da area nao escutam quem esta dentro.
- Jogadores dentro de areas privadas diferentes nao se escutam.
- Se nao houver private area, usa proximidade normal.

```dart
String? currentPrivateArea(TileCoord playerTile, List<TileZone> zones) {
  for (final zone in zones) {
    if (zone.type == TileEffectType.privateArea && zone.contains(playerTile)) {
      return zone.id;
    }
  }
  return null;
}
```

## Spotlight

Spotlight e uma area onde uma pessoa pode transmitir para um grupo maior.

Regras sugeridas:

- Quem esta em um tile `spotlight` transmite para todos dentro da mesma sala.
- Quem nao esta em spotlight segue regra normal de proximidade.
- Pode haver limite de permissao: host, moderador ou palestrante.

## Audio e Video por Proximidade

O audio/video por proximidade deve ser calculado pelo backend ou por um coordenador de sala.

Modelo simples:

- Cada jogador envia posicao atual.
- O servidor calcula quem deve se conectar com quem.
- O servidor envia lista de peers proximos.
- Cliente cria/remove conexoes WebRTC conforme necessario.

Distancia:

```dart
double tileDistance(TileCoord a, TileCoord b) {
  final dx = (a.x - b.x).toDouble();
  final dy = (a.y - b.y).toDouble();
  return math.sqrt(dx * dx + dy * dy);
}
```

Regras:

- Ate 4 tiles: audio/video forte.
- 5 a 8 tiles: audio reduzido.
- Acima de 8 tiles: desconectar ou mutar.
- Private area sobrescreve proximidade.
- Spotlight sobrescreve alcance.

## Multiplayer

Arquitetura recomendada:

- Cliente Flutter renderiza e captura input.
- WebSocket sincroniza estado leve.
- Servidor e autoridade sobre sala, posicao final e presenca.
- WebRTC/LiveKit cuida de midia.

Eventos WebSocket:

```json
{
  "type": "player.move.request",
  "payload": {
    "playerId": "p1",
    "from": {"x": 10, "y": 5},
    "to": {"x": 11, "y": 5},
    "direction": "right"
  }
}
```

```json
{
  "type": "player.moved",
  "payload": {
    "playerId": "p1",
    "tile": {"x": 11, "y": 5},
    "direction": "right",
    "timestamp": 1710000000000
  }
}
```

Eventos principais:

- `room.join`
- `room.leave`
- `player.spawned`
- `player.move.request`
- `player.moved`
- `player.teleported`
- `player.updated`
- `object.interaction.started`
- `zone.entered`
- `zone.left`
- `proximity.peers.updated`

## Autoridade do Servidor

O cliente pode prever movimento localmente, mas o servidor deve validar:

- Se o jogador esta na sala correta.
- Se o tile de destino e adjacente.
- Se o tile nao esta bloqueado.
- Se o jogador nao esta se movendo rapido demais.
- Se o portal/interacao e permitido.

Se o servidor negar movimento, o cliente corrige a posicao.

## Camera

A camera deve seguir o jogador local.

Recomendacao:

- Camera centralizada no personagem.
- Limites presos ao tamanho do mapa.
- Zoom responsivo.
- Em mobile, permitir zoom levemente maior para leitura.

Em Flame:

```dart
camera.follow(playerComponent);
```

## Input

Desktop:

- WASD.
- Setas.
- Tecla `E` para interagir.
- Tecla `Esc` para fechar modal.

Mobile:

- Joystick virtual.
- Botao contextual para interagir.
- Toque em objeto proximo como alternativa.

O input deve ser bloqueado enquanto:

- Modal esta aberto.
- Usuario esta editando texto.
- Transicao de sala esta em andamento.

## Editor de Mapas

Existem duas abordagens.

### Abordagem 1: Tiled Map Editor

Mais simples e robusta.

Fluxo:

1. Criar mapa `.tmx` no Tiled.
2. Criar camadas com nomes padronizados.
3. Marcar colisao e zonas em object layers.
4. Importar com `flame_tiled`.
5. Converter metadados do Tiled para modelos Dart.

### Abordagem 2: Editor proprio em Flutter

Mais flexivel, mas mais caro.

Recursos necessarios:

- Grade de tiles.
- Paleta de tiles.
- Camadas.
- Ferramenta de pincel.
- Ferramenta de borracha.
- Selecionar objeto.
- Arrastar objeto.
- Configurar interacao.
- Pintar zona.
- Exportar JSON.

Para primeira versao, usar Tiled e melhor.

## Formato JSON Proprio

Mesmo usando `.tmx`, e util ter um JSON normalizado para backend.

```json
{
  "id": "office-main",
  "name": "Main Office",
  "tileSize": 32,
  "widthInTiles": 80,
  "heightInTiles": 45,
  "assets": {
    "background": "assets/maps/office/background.png",
    "tileset": "assets/maps/office/tileset.png"
  },
  "collision": [
    {"x": 0, "y": 0},
    {"x": 1, "y": 0}
  ],
  "objects": [
    {
      "id": "tv-1",
      "type": "interactive",
      "name": "Presentation TV",
      "tile": {"x": 12, "y": 8},
      "widthInTiles": 2,
      "heightInTiles": 1,
      "blocksMovement": true,
      "interaction": {
        "type": "openUrl",
        "payload": {
          "url": "https://example.com"
        }
      }
    }
  ],
  "zones": [
    {
      "id": "meeting-room-a",
      "type": "privateArea",
      "tiles": [
        {"x": 20, "y": 10},
        {"x": 21, "y": 10}
      ]
    }
  ],
  "spawnPoints": [
    {"id": "default", "x": 5, "y": 5}
  ]
}
```

## Estrutura de Pastas Flutter

```text
lib/
  game/
    scenario_game.dart
    scenario_world.dart
    camera_controller.dart
  scenario/
    models/
      scenario.dart
      tile_coord.dart
      scenario_object.dart
      tile_zone.dart
      player_state.dart
    loaders/
      tiled_scenario_loader.dart
      json_scenario_loader.dart
    systems/
      collision_system.dart
      interaction_system.dart
      zone_system.dart
      proximity_system.dart
  players/
    player_component.dart
    remote_player_component.dart
    avatar_animation_set.dart
  networking/
    room_socket.dart
    room_events.dart
    room_repository.dart
  media/
    proximity_media_controller.dart
    livekit_adapter.dart
  ui/
    interaction_prompt.dart
    mobile_joystick.dart
    call_overlay.dart
assets/
  maps/
  tilesets/
  avatars/
```

## Componentes Flame

Componentes principais:

- `ScenarioGame`: instancia principal do jogo.
- `ScenarioWorld`: mundo/cenario carregado.
- `PlayerComponent`: jogador local.
- `RemotePlayerComponent`: outros jogadores.
- `ScenarioObjectComponent`: objetos renderizados.
- `ZoneDebugComponent`: opcional para debug.
- `InteractionPromptComponent`: UI contextual.

```dart
class ScenarioGame extends FlameGame with HasKeyboardHandlerComponents {
  late final ScenarioWorld scenarioWorld;

  @override
  Future<void> onLoad() async {
    scenarioWorld = ScenarioWorld();
    await add(scenarioWorld);
  }
}
```

## Fluxo de Carregamento

1. Entrar em uma sala.
2. Buscar metadata da sala no backend.
3. Carregar mapa e assets.
4. Carregar matriz de colisao.
5. Criar jogador local no spawn.
6. Conectar WebSocket.
7. Receber jogadores ja presentes.
8. Inicializar media por proximidade.
9. Liberar input.

## Fluxo de Movimento Local

1. Input recebe direcao.
2. Se jogador esta parado, calcula proximo tile.
3. Sistema de colisao valida.
4. Cliente inicia animacao local.
5. Cliente envia `player.move.request`.
6. Servidor responde com `player.moved` ou correcao.
7. Cliente ajusta estado final.

## Fluxo de Movimento Remoto

1. Cliente recebe `player.moved`.
2. Procura componente do jogador remoto.
3. Se nao existir, cria.
4. Interpola da posicao atual ate a nova.
5. Atualiza direcao e animacao.
6. Recalcula prioridade de renderizacao.

## Portais e Troca de Sala

Portal e um tile ou objeto que leva para outra sala.

```dart
class PortalPayload {
  final String targetRoomId;
  final String targetSpawnId;

  const PortalPayload({
    required this.targetRoomId,
    required this.targetSpawnId,
  });
}
```

Fluxo:

1. Jogador entra no tile de portal ou interage com objeto portal.
2. Cliente solicita troca de sala.
3. Servidor valida.
4. Cliente mostra transicao.
5. Desconecta sala atual.
6. Carrega novo mapa.
7. Posiciona jogador no spawn de destino.
8. Reconecta presenca e media.

## Performance

Pontos criticos:

- Evitar renderizar objetos fora da camera.
- Agrupar camadas estaticas.
- Usar atlases/spritesheets.
- Nao criar/destruir componentes remotos a cada pacote de rede.
- Limitar frequencia de envio de posicao.
- Usar interpolacao em vez de enviar frame a frame.

Frequencia sugerida:

- Movimento em tile: enviar apenas quando destino muda.
- Movimento livre: enviar 10 a 20 updates por segundo.
- Presenca/media: recalcular proximidade 2 a 5 vezes por segundo.

## Debug

Adicionar modos de debug:

- Mostrar grid.
- Mostrar tiles bloqueados.
- Mostrar zonas.
- Mostrar private area atual.
- Mostrar peers de audio/video ativos.
- Mostrar ping e ultima atualizacao de rede.

## MVP Recomendado

Versao 1:

- Mapa Tiled carregado no Flame.
- Jogador local andando em grid.
- Colisao.
- Camera seguindo jogador.
- Objetos interativos simples.

Versao 2:

- WebSocket.
- Jogadores remotos.
- Spawn e troca de sala.
- Interpolacao remota.

Versao 3:

- Areas privadas.
- Audio por proximidade.
- Video por proximidade.
- Spotlight.

Versao 4:

- Editor visual ou importador avancado.
- Customizacao de avatar.
- Permissoes por sala.
- Moderacao.

## Decisoes Importantes

### Grid ou Movimento Livre

Grid e mais fiel ao Gather e simplifica:

- Colisao.
- Interacao.
- Sincronizacao.
- Areas privadas.

Movimento livre parece mais moderno, mas aumenta complexidade em colisao, pathing, sincronizacao e UX mobile.

Recomendacao: comecar com grid.

### Imagem Unica ou Tilemap

Imagem unica e simples para mapas pequenos e bonitos, mas ruim para edicao.

Tilemap e melhor para:

- Performance.
- Reutilizacao.
- Colisao.
- Edicao.
- Escalabilidade.

Recomendacao: usar tilemap com Tiled.

### WebRTC Puro ou LiveKit

WebRTC puro da controle, mas exige:

- Signaling.
- STUN/TURN.
- Gerenciamento de peers.
- Reconexao.
- Controle de qualidade.
- Mixagem/assinatura seletiva.

LiveKit reduz esse custo.

Recomendacao: usar LiveKit se audio/video for parte central do produto.

## Checklist de Implementacao

- [ ] Definir formato do mapa.
- [ ] Criar primeiro mapa no Tiled.
- [ ] Adicionar `flame` e `flame_tiled`.
- [ ] Criar `ScenarioGame`.
- [ ] Carregar mapa.
- [ ] Criar jogador local.
- [ ] Implementar input desktop.
- [ ] Implementar input mobile.
- [ ] Implementar colisao.
- [ ] Implementar prioridade por eixo Y.
- [ ] Implementar objetos interativos.
- [ ] Implementar zonas.
- [ ] Criar backend de sala.
- [ ] Criar WebSocket.
- [ ] Sincronizar jogadores remotos.
- [ ] Implementar private areas.
- [ ] Implementar proximidade.
- [ ] Integrar audio/video.
- [ ] Adicionar debug overlay.
- [ ] Criar testes para regras de colisao e zonas.

## Testes

Testes unitarios:

- `CollisionMap.isBlocked`.
- Movimento para tile livre.
- Movimento para tile bloqueado.
- Entrada e saida de zona.
- Calculo de private area.
- Calculo de proximidade.
- Ordenacao por prioridade Y.

Testes de integracao:

- Carregar mapa real.
- Spawnar jogador.
- Mover ate objeto.
- Interagir com objeto.
- Entrar em private area.
- Receber jogador remoto.

## Resumo Tecnico

Para implementar um Gather-like em Flutter, trate o produto como um jogo 2D multiplayer:

- Flutter renderiza a interface.
- Flame renderiza o mundo 2D.
- Tiled cria os mapas.
- WebSocket sincroniza jogadores.
- LiveKit/WebRTC gerencia audio e video.
- O backend valida movimento, presenca, salas e permissoes.

A base deve ser simples: grid 32x32, colisao por tile, personagens com spritesheet, camadas bem definidas e estado de sala sincronizado. Depois disso, private areas, spotlight e video por proximidade entram como regras sobre posicao e zona atual do jogador.
