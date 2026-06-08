import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter/scheduler.dart";

import "../../../../core/theme/app_colors.dart";
import "../../../avatar/data/avatar_scene_loader.dart";
import "../../../avatar/domain/avatar_direction.dart";
import "../../../avatar/domain/avatar_position.dart";
import "../../../avatar/domain/avatar_scene.dart";
import "../../../avatar/presentation/avatar_movement_controller.dart";
import "../../../avatar/presentation/avatar_renderer.dart";
import "../../data/workspace_service.dart";
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
    super.key,
  });

  final String characterId;
  final String displayName;
  final String workspaceId;
  final String token;

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

  // key hold tracking
  final _heldKeys = <LogicalKeyboardKey>{};
  Timer? _walkTimer;
  DateTime? _lastMoveAt;
  static const _moveIntervalMs = 120;

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
        collidingIds,
        passthroughTileIds: passthroughIds,
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
  }

  void _tickMovement() {
    final dir = _currentDirection();
    if (dir == null) {
      _movementController?.stop();
      return;
    }
    final now = DateTime.now();
    if (_lastMoveAt == null ||
        now.difference(_lastMoveAt!).inMilliseconds >= _moveIntervalMs) {
      _movementController?.move(dir);
      _lastMoveAt = now;
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
        child: RepaintBoundary(
          child: CustomPaint(
            painter: MapRenderer(
              map: scene.map,
              colors: colors,
              imageCache: scene.imageCache,
              playerX: movementController.avatar.position.x,
              playerY: movementController.avatar.position.y,
              tileById: scene.tileById,
            ),
            foregroundPainter: AvatarRenderer(
              map: scene.map,
              colors: colors,
              frameImages: scene.avatarScene.frameImages,
              avatarController: scene.avatarScene.avatarController,
              avatar: movementController.avatar,
            ),
            child: const SizedBox.expand(),
          ),
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
