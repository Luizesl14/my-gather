import "dart:async";
import "dart:convert";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter/scheduler.dart";

import "../../../../core/theme/app_colors.dart";
import "../../../../core/theme/app_spacing.dart";
import "../../../avatar/data/avatar_scene_loader.dart";
import "../../../avatar/domain/avatar_direction.dart";
import "../../../avatar/domain/avatar_position.dart";
import "../../../avatar/domain/avatar_scene.dart";
import "../../../avatar/presentation/avatar_animation_controller.dart";
import "../../../avatar/presentation/avatar_movement_controller.dart";
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
    this.presenceDotColor,
    this.statusEmoji,
    this.reactionSprite,
    this.reactionTargetName,
    this.remoteAvatars = const {},
    this.onAvatarMoved,
    this.onAvatarStopped,
    super.key,
  });

  final String characterId;
  final String displayName;
  final String workspaceId;
  final String token;
  // Map owners/admins can toggle the collision overlay; guests never see it.
  final bool canToggleCollision;
  // Resolved presence color and optional status emoji shown in the name bubble.
  final Color? presenceDotColor;
  final String? statusEmoji;
  // Transient reaction bubble sprite (asset path relative to assets/) and the
  // optional name of who the gesture is aimed at ("wave at Maria").
  final String? reactionSprite;
  final String? reactionTargetName;
  // Remote avatars from WebSocket — keyed by userId.
  final Map<String, RemoteAvatar> remoteAvatars;
  // Called on every position update so the parent can relay to WebSocket.
  final void Function(double x, double y, String direction, String motionState)? onAvatarMoved;
  final void Function(double x, double y, String direction)? onAvatarStopped;

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

  // Collision overlay (owner/admin only).
  bool _showCollision = false;

  // key hold tracking
  final _heldKeys = <LogicalKeyboardKey>{};
  Timer? _walkTimer;
  DateTime? _lastMoveAt;
  static const _moveIntervalMs = 120;
  bool _wasMoving = false;

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
          "spawn": data.spawn,
          "layers": data.layers,
          "interactiveZones": data.interactiveZones,
        },
        const <String>{},
        passthroughTileIds: const <String>{},
      );
    } catch (_) {
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

      final character = catalog.characters.firstWhere(
        (c) => c.id == remote.characterId,
        orElse: () => catalog.defaultCharacter,
      );

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

  void _tickMovement() {
    final dir = _currentDirection();
    final controller = _movementController;

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

  @override
  void dispose() {
    _ticker?.dispose();
    _walkTimer?.cancel();
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

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = Size(constraints.maxWidth, constraints.maxHeight);
            final pos = movementController.avatar.position;
            return Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: MapRenderer(
                      map: scene.map,
                      colors: colors,
                      imageCache: scene.imageCache,
                      playerX: pos.x,
                      playerY: pos.y,
                      tileById: scene.tileById,
                      showCollisionDebug: _showCollision,
                    ),
                    foregroundPainter: AvatarRenderer(
                      map: scene.map,
                      colors: colors,
                      frameImages: scene.avatarScene.frameImages,
                      avatarController: scene.avatarScene.avatarController,
                      avatar: movementController.avatar,
                      presenceDotColor: widget.presenceDotColor,
                      statusEmoji: widget.statusEmoji,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                // Remote avatars layer — drawn on top of map, below reaction bubbles.
                if (widget.remoteAvatars.isNotEmpty)
                  CustomPaint(
                    painter: RemoteAvatarsRenderer(
                      map: scene.map,
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
                            ),
                      ],
                    ),
                    child: const SizedBox.expand(),
                  ),
                if (widget.reactionSprite != null)
                  _ReactionBubble(
                    sprite: widget.reactionSprite!,
                    targetName: widget.reactionTargetName,
                    map: scene.map,
                    viewport: viewport,
                    tileX: pos.x,
                    tileY: pos.y,
                  ),
                if (widget.canToggleCollision)
                  Positioned(
                    top: AppSpacing.xl,
                    right: AppSpacing.xl,
                    child: _CollisionToggle(
                      active: _showCollision,
                      colors: colors,
                      onTap: () =>
                          setState(() => _showCollision = !_showCollision),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isMovementKey = _directionFor(event.logicalKey) != null;
    if (!isMovementKey) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (!_heldKeys.contains(event.logicalKey)) {
        _heldKeys.add(event.logicalKey);
        _lastMoveAt = null; // move immediately on first press
      }
    } else if (event is KeyUpEvent) {
      _heldKeys.remove(event.logicalKey);
    }
    return KeyEventResult.handled;
  }
}

// Pill toggle for the collision overlay — visible to map owners/admins only.
class _CollisionToggle extends StatelessWidget {
  const _CollisionToggle({
    required this.active,
    required this.colors,
    required this.onTap,
  });

  final bool active;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active ? "Ocultar áreas de colisão" : "Mostrar áreas de colisão",
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? colors.brandPrimary
                  : colors.panel.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? colors.brandPrimary : colors.border,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.grid_on : Icons.grid_off,
                  size: 15,
                  color: active ? Colors.white : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  "Colisão",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    const zoom = MapRenderer.kDisplayZoom;
    final ts = map.tileSize * zoom;
    final offset = MapRenderer.cameraOffset(viewport, map, tileX, tileY);
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
                child: Image.asset(
                  "assets/$sprite",
                  filterQuality: FilterQuality.none,
                ),
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
