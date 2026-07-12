import "dart:async";
import "dart:convert";
import "dart:ui" as ui;

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter/scheduler.dart";

import "../../../../core/theme/app_colors.dart";
import "../../../avatar/data/avatar_scene_loader.dart";
import "../../../avatar/data/reaction_audio_service.dart";
import "../../../avatar/domain/avatar_direction.dart";
import "../../../avatar/domain/avatar_position.dart";
import "../../../avatar/domain/avatar_scene.dart";
import "../../../avatar/presentation/avatar_animation_controller.dart";
import "../../../avatar/presentation/avatar_movement_controller.dart";
import "../../../avatar/presentation/avatar_pathfinder.dart";
import "../../../avatar/presentation/gestures.dart";
import "../../../avatar/presentation/avatar_renderer.dart";
import "../../../avatar/presentation/remote_avatars_renderer.dart";
import "../../../avatar/domain/avatar_view_model.dart";
import "../../data/workspace_service.dart";
import "../remote_avatar_provider.dart";
import "map_image_cache.dart";
import "map_image_loader.dart";
import "map_renderer.dart";
import "office_map.dart";

class _OfficeScene {
  const _OfficeScene({
    required this.map,
    required this.avatarScene,
    required this.imageCache,
    required this.tileById,
  });
  final OfficeMap map;
  final AvatarScene avatarScene;
  final MapImageCache imageCache;
  final Map<String, TileDef> tileById;
}

class OfficeCanvas extends StatefulWidget {
  const OfficeCanvas({
    required this.characterId,
    required this.displayName,
    required this.workspaceId,
    required this.token,
    this.canToggleCollision = false,
    this.showCollision = false,
    this.presenceDotColor,
    this.statusEmoji,
    this.subtitle,
    this.reactionSprite,
    this.reactionTargetName,
    this.remoteAvatars = const {},
    this.onAvatarMoved,
    this.onAvatarStopped,
    this.onGesture,
    this.presenceColorFor,
    super.key,
  });

  final String characterId;
  final String displayName;
  final String workspaceId;
  final String token;
  // Map owners/admins can toggle the collision overlay; guests never see it.
  final bool canToggleCollision;
  // Controlled by the parent (office floating menu) — draws the collision debug
  // overlay when true so the owner can compare with what they drew in the editor.
  final bool showCollision;
  // Resolved presence color and optional status emoji shown in the name bubble.
  final Color? presenceDotColor;
  final String? statusEmoji;
  // Segunda linha da etiqueta do avatar ("função | equipe"), opcional.
  final String? subtitle;
  // Transient reaction bubble sprite (asset path relative to assets/) and the
  // optional name of who the gesture is aimed at ("wave at Maria").
  final String? reactionSprite;
  final String? reactionTargetName;
  // Remote avatars from WebSocket — keyed by userId.
  final Map<String, RemoteAvatar> remoteAvatars;
  // Called on every position update so the parent can relay to WebSocket.
  final void Function(double x, double y, String direction, String motionState)? onAvatarMoved;
  final void Function(double x, double y, String direction)? onAvatarStopped;
  // Called when the user picks a gesture aimed at a peer (hover menu).
  final void Function(String sprite, String targetUserId)? onGesture;
  // Resolve a cor da bolinha de presença de um status remoto (via catálogo).
  final Color Function(String presenceStatus)? presenceColorFor;

  @override
  State<OfficeCanvas> createState() => _OfficeCanvasState();
}

class _OfficeCanvasState extends State<OfficeCanvas>
    with SingleTickerProviderStateMixin {
  // Tiles with collision=true that should still allow passage (none currently).
  static const _passableTileIds = <String>{};

  late Future<_OfficeScene> _sceneFuture;
  final FocusNode _focusNode = FocusNode(debugLabel: "office-canvas");
  _OfficeScene? _scene;
  AvatarMovementController? _movementController;

  // game loop
  Ticker? _ticker;

  // Local zoom override — scroll wheel adjusts the player's view.
  double? _localZoom;

  // key hold tracking
  final _heldKeys = <LogicalKeyboardKey>{};
  Timer? _walkTimer;
  DateTime? _lastMoveAt;
  static const _moveIntervalMs = 120;
  bool _wasMoving = false;

  // Footstep audio synced to the leg animation's footfall beat, but only while
  // the avatar is actually translating (silent when standing/blocked).
  AvatarPosition? _lastTickPos;
  DateTime? _lastMovedAt;
  int _lastStepBeat = -1;

  // Auto-walk (X → desk / tap-to-walk). A* path of tile coords to follow.
  List<({int x, int y})> _autoPath = const [];
  int _autoIndex = 0;
  String? _arriveDir; // direction to face on arrival (sit); null = just stop
  bool _isSitting = false;
  DateTime? _lastAutoAt;
  static const double _autoTilesPerSec = 4.0;
  // Last viewport size, captured in the LayoutBuilder for tap → tile math.
  Size _viewport = Size.zero;

  // Double-tap-to-walk: position captured on the second tap-down.
  Offset _doubleTapPos = Offset.zero;

  // Hover-over-avatar state (hand cursor + gesture menu on peers).
  MouseCursor _hoverCursor = MouseCursor.defer;
  String? _hoveredUserId;
  // Usuário com o cartão de crachá aberto (Nome/Função/Equipe).
  String? _badgeUserId;
  Offset? _hoverAnchor; // top-center of the hovered avatar, in canvas coords
  Timer? _hoverCloseTimer;

  // Remote avatar rendering cache — keyed by characterId for frames, userId for controllers.
  final _characterFrames = <String, Map<String, ui.Image>>{};
  final _remoteControllers = <String, AvatarAnimationController>{};

  @override
  void initState() {
    super.initState();
    _sceneFuture = _loadScene();
    _sceneFuture.then(_onSceneLoaded);
  }

  Future<_OfficeScene> _loadScene() async {
    // Load scenary-pack first so we have collision data before building the map.
    final tileById = await _loadTileById();
    final collidingIds = {
      // Legacy tiles not in scenary-pack
      "wall-office", "glass-wall",
      // Scenary-pack: walls block; doors and chairs are passable
      for (final e in tileById.entries)
        if (e.value.collision &&
            e.value.category != "door" &&
            !_passableTileIds.contains(e.key)) e.key,
    };
    // Door/portal tiles placed over walls should always allow passage.
    final passthroughIds = {
      for (final e in tileById.entries)
        if (e.value.category == "door") e.key,
    };
    final results = await Future.wait<Object?>([
      _loadMap(collidingIds, passthroughIds),
      AvatarSceneLoader.load(
        characterId: widget.characterId,
        displayName: widget.displayName,
      ),
      MapImageLoader.load(),
    ]);
    return _OfficeScene(
      map: results[0] as OfficeMap,
      avatarScene: results[1] as AvatarScene,
      imageCache: results[2] as MapImageCache,
      tileById: tileById,
    );
  }

  static Future<Map<String, TileDef>> _loadTileById() async {
    final text = await rootBundle.loadString("assets/tilesets/scenary-pack.json");
    final json = jsonDecode(text) as Map<String, dynamic>;
    final tiles = (json["tiles"] as List<dynamic>).cast<Map<String, dynamic>>();
    return {
      for (final t in tiles)
        t["id"] as String: TileDef(
          frameCols: ((t["frames"] as Map<String, dynamic>?)?["cols"] as int?) ?? 1,
          frameRows: ((t["frames"] as Map<String, dynamic>?)?["rows"] as int?) ?? 1,
          category: t["category"] as String,
          collision: (t["collision"] as bool?) ?? false,
        ),
    };
  }

  Future<OfficeMap> _loadMap(Set<String> collidingIds, Set<String> passthroughIds) async {
    if (widget.workspaceId == "office-default") {
      return OfficeMap.loadDefault(collidingIds, passthroughTileIds: passthroughIds);
    }
    try {
      final data = await WorkspaceService(widget.token).fetchMap(widget.workspaceId);
      // Editor-authored maps: collision comes ONLY from colRects drawn in the
      // map editor. Catalog defaults (collision:true tiles) do not block here.
      return OfficeMap.fromApiJson(
        {
          "id": data.id,
          "width": data.width,
          "height": data.height,
          "tileSize": data.tileSize,
          "displayZoom": data.displayZoom,
          "avatarScale": data.avatarScale,
          "avatarYOffset": data.avatarYOffset,
          "avatarXOffset": data.avatarXOffset,
          "spawn": data.spawn,
          "layers": data.layers,
          "interactiveZones": data.interactiveZones,
        },
        const <String>{},
        passthroughTileIds: const <String>{},
      );
    } catch (e) {
      // Fallback silencioso esconde bugs reais (ex.: spawn/escala salvos no
      // editor sendo ignorados). Loga o motivo para o problema ser visível.
      debugPrint("[MAP] falha ao carregar mapa de ${widget.workspaceId}: $e — usando mapa default");
      return OfficeMap.loadDefault(collidingIds, passthroughTileIds: passthroughIds);
    }
  }

  void _onSceneLoaded(_OfficeScene scene) {
    if (!mounted) return;
    final direction = avatarDirectionFromString(scene.map.spawn.direction);
    final avatar = scene.avatarScene.avatar.copyWith(
      position: AvatarPosition(x: scene.map.spawn.x.toDouble(), y: scene.map.spawn.y.toDouble()),
      direction: direction,
    );
    final controller = AvatarMovementController(
      map: scene.map,
      avatar: avatar,
      animationController: scene.avatarScene.avatarController,
    )..setInitialPosition(avatar.position, direction);

    _ticker = createTicker((_) {
      if (!mounted) return;
      _tickMovement();
      final c = _movementController;
      if (c != null) _maybeFootstep(c.avatar.position);
      setState(() {});
    })..start();

    setState(() {
      _scene = scene;
      _movementController = controller;
    });

    _syncRemoteAvatars(widget.remoteAvatars, scene);
  }

  @override
  void didUpdateWidget(OfficeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remoteAvatars != widget.remoteAvatars && _scene != null) {
      _syncRemoteAvatars(widget.remoteAvatars, _scene!);
    }
  }

  void _syncRemoteAvatars(Map<String, RemoteAvatar> avatars, _OfficeScene scene) {
    final catalog = scene.avatarScene.catalog;

    for (final entry in avatars.entries) {
      final userId = entry.key;
      final remote = entry.value;

      final character =
          AvatarSceneLoader.resolveCharacter(catalog, remote.characterId);

      if (_remoteControllers.containsKey(userId)) {
        _remoteControllers[userId]!
          ..setDirection(remote.direction)
          ..setMotionState(remote.motionState);
      } else {
        _remoteControllers[userId] = AvatarAnimationController(
          character: character,
          direction: remote.direction,
          motionState: remote.motionState,
        );
      }

      if (!_characterFrames.containsKey(remote.characterId)) {
        AvatarSceneLoader.loadFrameImages(character).then((frames) {
          if (!mounted) return;
          setState(() => _characterFrames[remote.characterId] = frames);
        });
      }
    }

    // Remove controllers for users who left.
    _remoteControllers.removeWhere((uid, _) => !avatars.containsKey(uid));
  }

  // Plays a footstep on each footfall of the walk animation, but only while the
  // avatar actually translated this tick (so it's silent when standing/blocked).
  void _maybeFootstep(AvatarPosition pos) {
    final last = _lastTickPos;
    _lastTickPos = pos;
    // Manual movement advances in discrete 0.25-tile hops every ~120ms, so most
    // frames show no change — track the last time the avatar actually moved and
    // treat "moved within the last 220ms" as walking.
    if (last != null &&
        ((pos.x - last.x).abs() + (pos.y - last.y).abs()) > 0.0001) {
      _lastMovedAt = DateTime.now();
    }
    final anim = _scene?.avatarScene.avatarController;
    final recentlyMoved = _lastMovedAt != null &&
        DateTime.now().difference(_lastMovedAt!).inMilliseconds < 220;
    if (anim == null || !recentlyMoved) {
      _lastStepBeat = -1;
      return;
    }
    final beat = anim.stepBeat;
    if (beat < 0) {
      _lastStepBeat = -1;
      return;
    }
    if (beat != _lastStepBeat) {
      _lastStepBeat = beat;
      ReactionAudioService.playSfx("footstep");
    }
  }

  void _tickMovement() {
    final controller = _movementController;

    // Auto-walk (X-to-desk / tap-to-walk) takes priority over the keyboard.
    if (_autoPath.isNotEmpty && controller != null) {
      _tickAutoWalk(controller);
      return;
    }

    final dir = _currentDirection();

    if (dir == null) {
      if (_wasMoving && controller != null) {
        controller.stop();
        final pos = controller.avatar.position;
        widget.onAvatarStopped?.call(pos.x, pos.y, controller.avatar.direction.name);
        _wasMoving = false;
      } else {
        controller?.stop();
      }
      return;
    }

    final now = DateTime.now();
    if (_lastMoveAt == null ||
        now.difference(_lastMoveAt!).inMilliseconds >= _moveIntervalMs) {
      final moved = controller?.move(dir) ?? false;
      if (moved) {
        _lastMoveAt = now;
        _wasMoving = true;
        final pos = controller!.avatar.position;
        widget.onAvatarMoved?.call(pos.x, pos.y, dir.name, "walking");
      }
    }
  }

  void _tickAutoWalk(AvatarMovementController controller) {
    final now = DateTime.now();
    final dt = _lastAutoAt == null
        ? 0.016
        : (now.difference(_lastAutoAt!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastAutoAt = now;

    final wp = _autoPath[_autoIndex];
    final arrived =
        controller.stepToward(wp.x.toDouble(), wp.y.toDouble(), _autoTilesPerSec * dt);

    final pos = controller.avatar.position;
    widget.onAvatarMoved
        ?.call(pos.x, pos.y, controller.avatar.direction.name, "walking");

    if (!arrived) return;

    _autoIndex++;
    if (_autoIndex < _autoPath.length) return;

    // Reached the destination.
    _autoPath = const [];
    _autoIndex = 0;
    _lastAutoAt = null;
    if (_arriveDir != null) {
      controller.faceAndIdle(avatarDirectionFromString(_arriveDir!));
      _isSitting = true;
    } else {
      controller.stop();
    }
    final p = controller.avatar.position;
    widget.onAvatarStopped
        ?.call(p.x, p.y, controller.avatar.direction.name);
  }

  // Cancels any auto-walk / sitting (called when the user takes manual control).
  void _cancelAutoWalk() {
    if (_autoPath.isEmpty && !_isSitting) return;
    _autoPath = const [];
    _autoIndex = 0;
    _arriveDir = null;
    _isSitting = false;
    _lastAutoAt = null;
  }

  // X pressed: walk to the nearest desk and sit, or stand up if already seated.
  void _toggleSit() {
    final controller = _movementController;
    final scene = _scene;
    if (controller == null || scene == null) return;

    if (_isSitting || _autoPath.isNotEmpty) {
      setState(_cancelAutoWalk);
      controller.stop();
      return;
    }

    final desks = scene.map.desks;
    if (desks.isEmpty) return;

    final pos = controller.avatar.position;
    MapDesk? best;
    var bestDist = double.infinity;
    for (final d in desks) {
      final dd = (d.x - pos.x).abs() + (d.y - pos.y).abs();
      if (dd < bestDist) {
        bestDist = dd;
        best = d;
      }
    }
    final desk = best!;

    if (pos.tileX == desk.x && pos.tileY == desk.y) {
      controller.faceAndIdle(avatarDirectionFromString(desk.dir));
      setState(() => _isSitting = true);
      return;
    }

    final path = AvatarPathfinder.findPath(
        scene.map, pos.tileX, pos.tileY, desk.x, desk.y);
    if (path.isEmpty) return; // unreachable

    setState(() {
      _autoPath = path;
      _autoIndex = 0;
      _arriveDir = desk.dir;
      _isSitting = false;
      _lastAutoAt = null;
    });
  }

  // Tap a free tile to walk there (A* around obstacles).
  void _onTapWalk(Offset local) {
    _focusNode.requestFocus();
    final controller = _movementController;
    final scene = _scene;
    if (controller == null || scene == null || _viewport == Size.zero) return;

    final map = _effectiveMap(scene.map);
    final zoom = map.displayZoom;
    final pos = controller.avatar.position;
    final offset = MapRenderer.cameraOffset(_viewport, map, pos.x, pos.y, zoom: zoom);
    final cell = map.tileSize * zoom;
    final tx = ((local.dx - offset.dx) / cell).floor();
    final ty = ((local.dy - offset.dy) / cell).floor();
    if (tx < 0 || ty < 0 || tx >= map.width || ty >= map.height) return;
    if (!map.canOccupyTile(tx, ty)) return;

    final path = AvatarPathfinder.findPath(map, pos.tileX, pos.tileY, tx, ty);
    if (path.isEmpty) return;

    setState(() {
      _autoPath = path;
      _autoIndex = 0;
      _arriveDir = null;
      _isSitting = false;
      _lastAutoAt = null;
    });
  }

  // Approximate screen rect of an avatar standing at tile (tx, ty) — mirrors
  // the renderers closely enough for hover hit-testing.
  Rect _avatarRect(
      OfficeMap map, Offset camOffset, double ts, double tx, double ty) {
    final cx = (tx + 0.5 + map.avatarXOffset) * ts + camOffset.dx;
    final bottomY = (ty + 1 - map.avatarYOffset) * ts + camOffset.dy;
    final h = ts * map.avatarScale;
    final w = ts * 0.8;
    return Rect.fromLTWH(cx - w / 2, bottomY - h, w, h);
  }

  void _onHover(Offset local) {
    final scene = _scene;
    final controller = _movementController;
    if (scene == null || controller == null || _viewport == Size.zero) return;
    final map = _effectiveMap(scene.map);
    final ts = map.tileSize * map.displayZoom;
    final localPos = controller.avatar.position;
    final camOffset = MapRenderer.cameraOffset(
        _viewport, map, localPos.x, localPos.y,
        zoom: map.displayZoom);

    String? hitUserId;
    Rect? hitRect;
    for (final entry in widget.remoteAvatars.entries) {
      final r = _avatarRect(
          map, camOffset, ts, entry.value.position.x, entry.value.position.y);
      if (r.contains(local)) {
        hitUserId = entry.key;
        hitRect = r;
      }
    }
    final overLocal =
        _avatarRect(map, camOffset, ts, localPos.x, localPos.y).contains(local);
    final cursor = (hitUserId != null || overLocal)
        ? SystemMouseCursors.click
        : MouseCursor.defer;

    if (hitUserId != null) {
      final r = hitRect!;
      _hoverCloseTimer?.cancel();
      if (_hoveredUserId != hitUserId || _hoverCursor != cursor) {
        setState(() {
          _hoveredUserId = hitUserId;
          _hoverAnchor = Offset(r.center.dx, r.top);
          _hoverCursor = cursor;
        });
      }
    } else {
      if (_hoverCursor != cursor) setState(() => _hoverCursor = cursor);
      if (_hoveredUserId != null) _scheduleHoverClose();
    }
  }

  void _scheduleHoverClose() {
    _hoverCloseTimer?.cancel();
    _hoverCloseTimer = Timer(const Duration(milliseconds: 250), () {
      // Com o crachá aberto o cartão fica fixo até fechar no X — sem isso,
      // o mouse "sai" do menu ao trocar para o cartão e tudo some na hora.
      if (mounted && _badgeUserId == null) {
        setState(() => _hoveredUserId = null);
      }
    });
  }

  void _clearHover() {
    _hoverCloseTimer?.cancel();
    if (_hoveredUserId != null || _hoverCursor != MouseCursor.defer) {
      setState(() {
        _hoveredUserId = null;
        _hoverCursor = MouseCursor.defer;
      });
    }
  }

  AvatarDirection? _currentDirection() {
    for (final key in _heldKeys) {
      final dir = _directionFor(key);
      if (dir != null) return dir;
    }
    return null;
  }

  AvatarDirection? _directionFor(LogicalKeyboardKey key) => switch (key) {
    LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => AvatarDirection.back,
    LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => AvatarDirection.front,
    LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => AvatarDirection.left,
    LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyD => AvatarDirection.right,
    _ => null,
  };

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final base = _scene?.map.displayZoom ?? 2.5;
    final current = _localZoom ?? base;
    final factor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
    final next = (current * factor).clamp(1.0, 4.0);
    if (next == current) return;
    setState(() => _localZoom = next);
  }

  OfficeMap _effectiveMap(OfficeMap map) =>
      _localZoom != null ? map.withZoom(_localZoom!) : map;

  @override
  void dispose() {
    _ticker?.dispose();
    _walkTimer?.cancel();
    _hoverCloseTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scene = _scene;
    final movementController = _movementController;

    if (scene == null || movementController == null) {
      return ColoredBox(
        color: colors.app,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              Text(
                "Carregando escritório...",
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Listener(
      onPointerSignal: _onPointerSignal,
      child: Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: _hoverCursor,
        onHover: (e) => _onHover(e.localPosition),
        onExit: (_) => _clearHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        // Double-click to walk (single click only focuses).
        onDoubleTapDown: (d) => _doubleTapPos = d.localPosition,
        onDoubleTap: () => _onTapWalk(_doubleTapPos),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = Size(constraints.maxWidth, constraints.maxHeight);
            _viewport = viewport;
            final pos = movementController.avatar.position;
            final effectiveMap = _effectiveMap(scene.map);
            return Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: MapRenderer(
                      map: effectiveMap,
                      colors: colors,
                      imageCache: scene.imageCache,
                      playerX: pos.x,
                      playerY: pos.y,
                      tileById: scene.tileById,
                      showCollisionDebug: widget.showCollision,
                    ),
                    foregroundPainter: AvatarRenderer(
                      map: effectiveMap,
                      colors: colors,
                      frameImages: scene.avatarScene.frameImages,
                      avatarController: scene.avatarScene.avatarController,
                      // displayName vem do widget (authProvider): editar o
                      // perfil atualiza o balão sem recarregar a cena.
                      avatar: movementController.avatar
                          .copyWith(displayName: widget.displayName),
                      presenceDotColor: widget.presenceDotColor,
                      statusEmoji: widget.statusEmoji,
                      subtitle: widget.subtitle,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                // Remote avatars layer — drawn on top of map, below reaction bubbles.
                if (widget.remoteAvatars.isNotEmpty)
                  CustomPaint(
                    painter: RemoteAvatarsRenderer(
                      map: effectiveMap,
                      colors: colors,
                      localPosition: pos,
                      remotes: [
                        for (final entry in widget.remoteAvatars.entries)
                          if (_remoteControllers.containsKey(entry.key))
                            RemoteAvatarEntry(
                              frameImages: _characterFrames[entry.value.characterId] ?? const {},
                              controller: _remoteControllers[entry.key]!,
                              viewModel: AvatarViewModel(
                                characterId: entry.value.characterId,
                                displayName: entry.value.displayName,
                                position: entry.value.position,
                                direction: entry.value.direction,
                                motionState: entry.value.motionState,
                                presenceLabel: entry.value.presenceStatus,
                              ),
                              subtitle: [entry.value.role, entry.value.team]
                                  .where((s) => s.trim().isNotEmpty)
                                  .join(" | "),
                              dotColor: widget.presenceColorFor
                                  ?.call(entry.value.presenceStatus),
                            ),
                      ],
                    ),
                    child: const SizedBox.expand(),
                  ),
                // Collision debug overlay — drawn ABOVE avatars so the player
                // hitbox stays visible when centered on the character sprite.
                if (widget.showCollision)
                  CustomPaint(
                    painter: CollisionDebugPainter(
                      map: effectiveMap,
                      playerX: pos.x,
                      playerY: pos.y,
                    ),
                    child: const SizedBox.expand(),
                  ),
                if (widget.reactionSprite != null)
                  _ReactionBubble(
                    sprite: widget.reactionSprite!,
                    targetName: widget.reactionTargetName,
                    map: effectiveMap,
                    viewport: viewport,
                    tileX: pos.x,
                    tileY: pos.y,
                  ),
                // Gesture menu shown over a peer's avatar on hover.
                if (_hoveredUserId != null &&
                    _hoverAnchor != null &&
                    widget.onGesture != null)
                  Positioned(
                    left: _hoverAnchor!.dx - (kGestures.length * 38) / 2,
                    top: _hoverAnchor!.dy - 56,
                    child: MouseRegion(
                      onEnter: (_) => _hoverCloseTimer?.cancel(),
                      onExit: (_) => _scheduleHoverClose(),
                      child: _buildPeerGestureMenu(_hoveredUserId!),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildPeerGestureMenu(String userId) {
    // Crachá aberto: mostra o cartão com Nome / Função / Equipe no lugar dos
    // gestos (fechar volta para o menu).
    if (_badgeUserId == userId) {
      final remote = widget.remoteAvatars[userId];
      return _buildPeerBadgeCard(remote);
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xF21A1E2B),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final g in kGestures)
              Tooltip(
                message: g.label,
                child: InkWell(
                  onTap: () {
                    widget.onGesture?.call(g.sprite, userId);
                    _clearHover();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Image.asset(
                        "assets/${g.sprite}",
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              ),
            Tooltip(
              message: "Crachá",
              child: InkWell(
                onTap: () => setState(() => _badgeUserId = userId),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(Icons.badge_outlined,
                        size: 22, color: Colors.white70),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerBadgeCard(RemoteAvatar? remote) {
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$label  ",
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
              Text(value.isEmpty ? "—" : value,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        );

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
        decoration: BoxDecoration(
          color: const Color(0xF21A1E2B),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  remote?.displayName ?? "—",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() {
                    _badgeUserId = null;
                    _hoveredUserId = null;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child:
                        Icon(Icons.close, size: 14, color: Colors.white54),
                  ),
                ),
              ],
            ),
            line("FUNÇÃO", remote?.role ?? ""),
            line("EQUIPE", remote?.team ?? ""),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // X → walk to nearest desk and sit (or stand up).
    if (event.logicalKey == LogicalKeyboardKey.keyX) {
      if (event is KeyDownEvent) _toggleSit();
      return KeyEventResult.handled;
    }

    final isMovementKey = _directionFor(event.logicalKey) != null;
    if (!isMovementKey) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (!_heldKeys.contains(event.logicalKey)) {
        // Taking manual control cancels any auto-walk / sitting.
        if (_autoPath.isNotEmpty || _isSitting) setState(_cancelAutoWalk);
        _heldKeys.add(event.logicalKey);
        _lastMoveAt = null; // move immediately on first press
      }
    } else if (event is KeyUpEvent) {
      _heldKeys.remove(event.logicalKey);
    }
    return KeyEventResult.handled;
  }
}

// Transient reaction bubble above the player's avatar, Gather-style.
// Positioned with the same camera math used by MapRenderer/AvatarRenderer.
class _ReactionBubble extends StatelessWidget {
  const _ReactionBubble({
    required this.sprite,
    required this.map,
    required this.viewport,
    required this.tileX,
    required this.tileY,
    this.targetName,
  });

  final String sprite;
  final String? targetName;
  final OfficeMap map;
  final Size viewport;
  final double tileX;
  final double tileY;

  @override
  Widget build(BuildContext context) {
    final zoom = map.displayZoom;
    final ts = map.tileSize * zoom;
    final offset = MapRenderer.cameraOffset(viewport, map, tileX, tileY, zoom: zoom);
    // Sprites are 32px pixel art: render at native size to keep them crisp.
    const bubbleSize = 44.0;
    const colWidth = 140.0;
    final chipHeight = targetName == null ? 0.0 : 20.0;
    // Above the sprite (48px tall) and the name bubble (~30px).
    final left = tileX * ts + offset.dx + ts / 2 - colWidth / 2;
    final top =
        tileY * ts + offset.dy + ts - 48 - 30 - bubbleSize - chipHeight - 6;

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: colWidth,
        child: TweenAnimationBuilder<double>(
          key: ValueKey("$sprite-$targetName"),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: bubbleSize,
                height: bubbleSize,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xF2FFFFFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x55000000), blurRadius: 8),
                  ],
                ),
                child: _WigglingSprite(sprite: sprite),
              ),
              if (targetName != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xD9172033),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    "→ $targetName",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Pixel-art gesture sprite that gently rocks back and forth (Gather-style wave).
class _WigglingSprite extends StatefulWidget {
  const _WigglingSprite({required this.sprite});

  final String sprite;

  @override
  State<_WigglingSprite> createState() => _WigglingSpriteState();
}

class _WigglingSpriteState extends State<_WigglingSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..repeat(reverse: true);

  late final Animation<double> _wiggle = Tween<double>(begin: -0.06, end: 0.06)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _wiggle,
      alignment: Alignment.bottomCenter,
      child: Image.asset(
        "assets/${widget.sprite}",
        filterQuality: FilterQuality.none,
      ),
    );
  }
}
