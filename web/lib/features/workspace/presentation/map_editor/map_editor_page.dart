import "dart:convert";
import "dart:math" show pi;
import "dart:ui" as ui;

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/app_colors.dart";
import "../../../../core/theme/app_spacing.dart";
import "../../../../shared/design_system/design_system.dart";
import "../../../auth/presentation/auth_provider.dart";
import "../../data/workspace_service.dart" show WorkspaceService, extractApiError;
import "../game/map_image_loader.dart";
import "map_editor_state.dart";

// ─── Providers ───────────────────────────────────────────────────────────────

final _scenaryPackProvider =
    FutureProvider.autoDispose<List<ScenaryTile>>((ref) async {
  final text =
      await rootBundle.loadString("assets/tilesets/scenary-pack.json");
  final json = jsonDecode(text) as Map<String, dynamic>;
  return (json["tiles"] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(ScenaryTile.fromJson)
      .toList(growable: false);
});

final _editorImagesProvider =
    FutureProvider.autoDispose<Map<String, ui.Image>>((ref) async {
  final cache = await MapImageLoader.load();
  return cache.tiles;
});

// ─── Page ────────────────────────────────────────────────────────────────────

class MapEditorPage extends ConsumerStatefulWidget {
  const MapEditorPage({required this.workspaceId, super.key});
  final String workspaceId;

  @override
  ConsumerState<MapEditorPage> createState() => _MapEditorPageState();
}

class _MapEditorPageState extends ConsumerState<MapEditorPage> {
  @override
  void initState() {
    super.initState();
    _loadExistingMap();
  }

  Future<void> _loadExistingMap() async {
    final token = ref.read(authProvider).token ?? "";
    try {
      final data = await WorkspaceService(token).fetchMap(widget.workspaceId);
      if (!mounted) return;
      ref
          .read(mapEditorProvider((widget.workspaceId, token)).notifier)
          .loadFromApiData(data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erro ao carregar mapa: ${extractApiError(e)}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final token = ref.watch(authProvider).token ?? "";
    final editorKey = (widget.workspaceId, token);
    final editorState = ref.watch(mapEditorProvider(editorKey));
    final notifier = ref.read(mapEditorProvider(editorKey).notifier);
    final tilesAsync = ref.watch(_scenaryPackProvider);
    final imagesAsync = ref.watch(_editorImagesProvider);

    final tiles = tilesAsync.valueOrNull ?? const [];
    final tileById = {for (final t in tiles) t.id: t};
    final overlayTiles =
        tiles.where((t) => t.isOverlay).toList(growable: false);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final sel = editorState.selectedId;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          notifier.clearSelection();
          return KeyEventResult.handled;
        }
        if (sel != null) {
          final tile = editorState.selectedTile!;
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            notifier.deletePlaced(sel);
            return KeyEventResult.handled;
          }
          int? nx, ny;
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            nx = tile.x - 1;
            ny = tile.y;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            nx = tile.x + 1;
            ny = tile.y;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            nx = tile.x;
            ny = tile.y - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            nx = tile.x;
            ny = tile.y + 1;
          }
          if (nx != null && ny != null) {
            notifier.movePlaced(sel, nx, ny);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: colors.canvas,
        body: Column(
          children: [
            _EditorToolbar(
              editorState: editorState,
              notifier: notifier,
              colors: colors,
              tileById: tileById,
              overlayTiles: overlayTiles,
              onBack: () => context.goNamed(AppRouteNames.workspaceSelection),
            ),
            Expanded(
              child: Row(
                children: [
                  // Palette
                  tilesAsync.when(
                    loading: () => const SizedBox(
                        width: 200,
                        child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox(width: 200),
                    data: (tiles) => _ScenaryPalette(
                      tiles: tiles,
                      activeLayer: editorState.activeLayer,
                      paletteSelectedId: editorState.paletteSelectedId,
                      onSelectLayer: notifier.setActiveLayer,
                      onSelect: (tile) => notifier.selectPaletteTile(
                          tile.id, tile.sizeW, tile.sizeH, tile.category,
                          frameCols: tile.frameCols, frameRows: tile.frameRows),
                      onDeselect: notifier.clearPaletteSelection,
                      colors: colors,
                    ),
                  ),
                  // Canvas
                  Expanded(
                    child: imagesAsync.when(
                      loading: () => const ColoredBox(
                        color: Color(0xFF1E2533),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (images) => _EditorCanvas(
                        editorState: editorState,
                        tileById: tileById,
                        images: images,
                        notifier: notifier,
                        colors: colors,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toolbar ─────────────────────────────────────────────────────────────────

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.editorState,
    required this.notifier,
    required this.colors,
    required this.tileById,
    required this.overlayTiles,
    required this.onBack,
  });

  final MapEditorData editorState;
  final MapEditorNotifier notifier;
  final AppColors colors;
  final Map<String, ScenaryTile> tileById;
  final List<ScenaryTile> overlayTiles;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final selected = editorState.selectedTile;
    final selDef = selected != null ? tileById[selected.tileId] : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main row
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back,
                    tooltip: "Voltar",
                    onPressed: onBack,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    "Editor de Mapa",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (editorState.isDirty)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Text(
                        "Não salvo",
                        style:
                            TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
                    ),
                  AppIconButton(
                    icon: Icons.delete_sweep_outlined,
                    tooltip: "Limpar tudo",
                    onPressed: notifier.clearAll,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton.icon(
                    onPressed: editorState.isSaving
                        ? null
                        : () async {
                            try {
                              await notifier.save();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Mapa salvo!")),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Erro ao salvar: ${extractApiError(e)}"),
                                  ),
                                );
                              }
                            }
                          },
                    icon: editorState.isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 16),
                    label: const Text("Salvar"),
                  ),
                ],
              ),
            ),
          ),

          // Context row: only when something is selected
          if (selected != null)
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.panelMuted,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  // Base actions (all layers)
                  _ContextAction(
                    icon: Icons.rotate_right,
                    tooltip: "Girar 90°",
                    onPressed: () => notifier.rotatePlaced(selected.id),
                    colors: colors,
                  ),
                  _ContextAction(
                    icon: Icons.flip,
                    tooltip: "Espelhar",
                    onPressed: () => notifier.flipPlaced(selected.id),
                    colors: colors,
                  ),

                  _ContextDivider(colors: colors),

                  // Frame controls (chairs, tables with multiple views)
                  if (selDef != null)
                    ..._buildObjectControls(context, selected, selDef),

                  // Walls: overlay picker
                  if (editorState.activeLayer == "walls" &&
                      selDef != null &&
                      selDef.acceptsOverlay)
                    ..._buildOverlayPicker(context, selected),

                  const Spacer(),

                  _ContextAction(
                    icon: Icons.delete_outline,
                    tooltip: "Deletar (Del)",
                    onPressed: () => notifier.deletePlaced(selected.id),
                    colors: colors,
                    danger: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildObjectControls(
    BuildContext context,
    PlacedTile sel,
    ScenaryTile def,
  ) {
    final hasFrames = def.frameCols > 1 || def.frameRows > 1;
    if (!hasFrames) return [];

    final totalFrames = def.frameCols * def.frameRows;
    final currentFrame = sel.frameRow * def.frameCols + sel.frameCol + 1;

    return [
      Text("Variante:", style: TextStyle(color: colors.textMuted, fontSize: 11)),
      const SizedBox(width: 4),
      _ContextAction(
        icon: Icons.chevron_left,
        tooltip: "Anterior",
        onPressed: () =>
            notifier.prevFrame(sel.id, def.frameCols, def.frameRows),
        colors: colors,
      ),
      Text(
        "$currentFrame/$totalFrames",
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      _ContextAction(
        icon: Icons.chevron_right,
        tooltip: "Próxima",
        onPressed: () =>
            notifier.nextFrame(sel.id, def.frameCols, def.frameRows),
        colors: colors,
      ),
    ];
  }

  List<Widget> _buildOverlayPicker(BuildContext context, PlacedTile sel) {
    return [
      Text("Overlay:",
          style: TextStyle(color: colors.textMuted, fontSize: 11)),
      const SizedBox(width: 4),
      // "Nenhum" chip
      _OverlayChip(
        label: "Nenhum",
        isActive: sel.overlayId == null,
        onTap: () => notifier.setOverlay(sel.id, null),
        colors: colors,
      ),
      const SizedBox(width: 4),
      ...overlayTiles.map((ot) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Tooltip(
              message: ot.label,
              child: GestureDetector(
                onTap: () => notifier.setOverlay(
                    sel.id,
                    sel.overlayId == ot.id ? null : ot.id),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: sel.overlayId == ot.id
                          ? colors.brandPrimary
                          : colors.border,
                      width: sel.overlayId == ot.id ? 2 : 1,
                    ),
                    color: sel.overlayId == ot.id
                        ? colors.brandPrimary.withValues(alpha: 0.1)
                        : colors.canvas,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.asset(
                      "assets/tilesets/${ot.path}",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          )),
    ];
  }
}

class _ContextAction extends StatelessWidget {
  const _ContextAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colors,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final AppColors colors;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            size: 16,
            color: danger ? colors.red : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ContextDivider extends StatelessWidget {
  const _ContextDivider({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 20, color: colors.border,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm));
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? colors.brandPrimary : colors.border,
            width: isActive ? 1.5 : 1,
          ),
          color: isActive
              ? colors.brandPrimary.withValues(alpha: 0.1)
              : colors.canvas,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? colors.brandPrimary : colors.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Palette ─────────────────────────────────────────────────────────────────

class _ScenaryPalette extends StatelessWidget {
  const _ScenaryPalette({
    required this.tiles,
    required this.activeLayer,
    required this.paletteSelectedId,
    required this.onSelectLayer,
    required this.onSelect,
    required this.onDeselect,
    required this.colors,
  });

  final List<ScenaryTile> tiles;
  final String activeLayer;
  final String? paletteSelectedId;
  final void Function(String) onSelectLayer;
  final void Function(ScenaryTile) onSelect;
  final VoidCallback onDeselect;
  final AppColors colors;

  static const _layers = [
    ("floor", "Piso"),
    ("walls", "Paredes"),
    ("objects", "Objetos"),
  ];

  static const _layerCategories = {
    "floor": ["floor", "mat"],
    "walls": ["wall", "door", "window"],
    "objects": ["furniture"],
  };

  static const _categoryLabels = {
    "floor": "Piso",
    "mat": "Tapete",
    "wall": "Parede",
    "door": "Porta",
    "window": "Janela",
    "furniture": "Móveis",
  };

  @override
  Widget build(BuildContext context) {
    final visibleCats = _layerCategories[activeLayer] ?? [];
    final visibleTiles =
        tiles.where((t) => visibleCats.contains(t.category)).toList();

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Layer tabs
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: _layers.map((layer) {
                final isActive = layer.$1 == activeLayer;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectLayer(layer.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colors.brandPrimary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: isActive
                                ? colors.brandPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        layer.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isActive
                              ? colors.brandPrimary
                              : colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Tile list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: visibleCats.map((cat) {
                final catTiles =
                    visibleTiles.where((t) => t.category == cat).toList();
                if (catTiles.isEmpty) return const SizedBox.shrink();
                return _CategorySection(
                  label: _categoryLabels[cat] ?? cat,
                  tiles: catTiles,
                  selectedId: paletteSelectedId,
                  onSelect: onSelect,
                  colors: colors,
                );
              }).toList(),
            ),
          ),

          if (paletteSelectedId != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: OutlinedButton.icon(
                onPressed: onDeselect,
                icon: const Icon(Icons.close, size: 14),
                label: const Text("Cancelar"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.label,
    required this.tiles,
    required this.selectedId,
    required this.onSelect,
    required this.colors,
  });

  final String label;
  final List<ScenaryTile> tiles;
  final String? selectedId;
  final void Function(ScenaryTile) onSelect;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio: 1,
          ),
          itemCount: tiles.length,
          itemBuilder: (_, i) {
            final tile = tiles[i];
            final isSelected = selectedId == tile.id;
            final hasSize = tile.sizeW > 1 || tile.sizeH > 1;
            final hasFrames = tile.frameCols > 1 || tile.frameRows > 1;
            return Tooltip(
              message: hasSize
                  ? "${tile.label} (${tile.sizeW}×${tile.sizeH})"
                  : tile.label,
              child: InkWell(
                onTap: () => onSelect(tile),
                borderRadius: BorderRadius.circular(5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? colors.brandPrimary : colors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? colors.brandPrimary.withValues(alpha: 0.1)
                        : colors.canvas,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          "assets/tilesets/${tile.path}",
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            size: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      if (hasSize || hasFrames)
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.panel.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              hasSize
                                  ? "${tile.sizeW}×${tile.sizeH}"
                                  : "…",
                              style: TextStyle(
                                  fontSize: 7,
                                  color: colors.textMuted,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Canvas ──────────────────────────────────────────────────────────────────

class _EditorCanvas extends StatefulWidget {
  const _EditorCanvas({
    required this.editorState,
    required this.tileById,
    required this.images,
    required this.notifier,
    required this.colors,
  });

  final MapEditorData editorState;
  final Map<String, ScenaryTile> tileById;
  final Map<String, ui.Image> images;
  final MapEditorNotifier notifier;
  final AppColors colors;

  @override
  State<_EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<_EditorCanvas> {
  static const _baseCell = 32.0;
  static const _tapThreshold = 8.0;

  double _scale = 1.5;
  Offset _offset = const Offset(40, 40);
  bool _showCollision = true;

  double _scaleStart = 1.0;
  Offset _panStartPointer = Offset.zero;
  Offset _panStartOffset = Offset.zero;
  bool _didPan = false;

  String? _draggingId;
  int _dragStartTileX = 0;
  int _dragStartTileY = 0;
  Offset _dragStartPointer = Offset.zero;

  bool _draggingPixel = false; // true when dragging an object (pixel coords)

  // Move-handle drag state
  int _handleStartX = 0;
  int _handleStartY = 0;
  Offset _handleGlobalStart = Offset.zero;

  // Resize-handle drag state (objects only)
  int _resizeStartW = 1;
  int _resizeStartH = 1;
  Offset _resizeGlobalStart = Offset.zero;

  // Collision draw mode — non-null when user is drawing a collision rect
  String? _collisionEditId;
  Offset? _colDragStart;  // canvas-space start
  Offset? _colDragEnd;    // canvas-space current end

  // Tile action popover
  bool _showTileMenu = false;

  Offset _toCanvas(Offset screen) => (screen - _offset) / _scale;

  (int, int) _toGrid(Offset canvas) => (
        (canvas.dx / _baseCell).floor(),
        (canvas.dy / _baseCell).floor(),
      );

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final factor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
    final newScale = (_scale * factor).clamp(0.25, 4.0);
    final focal = event.localPosition;
    final canvasFocal = _toCanvas(focal);
    setState(() {
      _scale = newScale;
      _offset =
          focal - Offset(canvasFocal.dx * newScale, canvasFocal.dy * newScale);
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    // Collision draw mode — capture drag start and skip normal handling
    if (_collisionEditId != null && details.pointerCount == 1) {
      final cp = _toCanvas(details.localFocalPoint);
      setState(() {
        _colDragStart = cp;
        _colDragEnd = cp;
      });
      return;
    }

    _scaleStart = _scale;
    _panStartPointer = details.localFocalPoint;
    _panStartOffset = _offset;
    _draggingId = null;
    _didPan = false;

    _draggingPixel = false;

    // In paint mode, never setup tile drag — tap-end will place
    if (details.pointerCount == 1 &&
        widget.editorState.paletteSelectedId == null) {
      final canvasPos = _toCanvas(details.localFocalPoint);
      final activeLayer = widget.editorState.activeLayer;

      if (activeLayer != "floor") {
        // Pixel hit test — last (topmost) match wins
        PlacedTile? hit;
        for (final t in widget.editorState.placedTiles.values) {
          if (t.layerName == activeLayer &&
              canvasPos.dx >= t.x && canvasPos.dx < t.x + t.w &&
              canvasPos.dy >= t.y && canvasPos.dy < t.y + t.h) {
            hit = t;
          }
        }
        if (hit != null) {
          _draggingId = hit.id;
          _dragStartTileX = hit.x;
          _dragStartTileY = hit.y;
          _dragStartPointer = details.localFocalPoint;
          _draggingPixel = true;
        }
      } else {
        // Grid hit test for floor tiles
        final (gx, gy) = _toGrid(canvasPos);
        for (final t in widget.editorState.placedTiles.values) {
          if (t.layerName == activeLayer && t.hits(gx, gy)) {
            _draggingId = t.id;
            _dragStartTileX = t.x;
            _dragStartTileY = t.y;
            _dragStartPointer = details.localFocalPoint;
            break;
          }
        }
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Collision draw mode — update preview rect
    if (_collisionEditId != null && _colDragStart != null) {
      setState(() => _colDragEnd = _toCanvas(details.localFocalPoint));
      return;
    }

    if (_draggingId != null) {
      final delta = details.localFocalPoint - _dragStartPointer;
      if (delta.distance > _tapThreshold) _didPan = true;
      final canvasDelta = delta / _scale;
      final int newX, newY;
      if (_draggingPixel) {
        // Objects: pixel-level movement (no grid snap)
        newX = _dragStartTileX + canvasDelta.dx.round();
        newY = _dragStartTileY + canvasDelta.dy.round();
      } else {
        // Floor/walls: snap to grid cells
        newX = _dragStartTileX + (canvasDelta.dx / _baseCell).round();
        newY = _dragStartTileY + (canvasDelta.dy / _baseCell).round();
      }
      widget.notifier.movePlaced(_draggingId!, newX, newY);
      return;
    }

    if (details.pointerCount >= 2 || details.scale != 1.0) {
      _didPan = true;
      final newScale = (_scaleStart * details.scale).clamp(0.25, 4.0);
      final focal = details.localFocalPoint;
      final canvasFocal = _toCanvas(focal);
      setState(() {
        _scale = newScale;
        _offset = focal -
            Offset(canvasFocal.dx * newScale, canvasFocal.dy * newScale);
      });
    } else {
      final delta = details.localFocalPoint - _panStartPointer;
      if (delta.distance > _tapThreshold) _didPan = true;
      setState(() => _offset = _panStartOffset + delta);
    }
  }

  void _onScaleEnd(ScaleEndDetails _) {
    // Collision draw mode — always intercept so tapCanvas never fires mid-draw.
    if (_collisionEditId != null) {
      if (_colDragStart != null && _colDragEnd != null) {
        final x1 = _colDragStart!.dx;
        final y1 = _colDragStart!.dy;
        final x2 = _colDragEnd!.dx;
        final y2 = _colDragEnd!.dy;
        final rx = x1 < x2 ? x1 : x2;
        final ry = y1 < y2 ? y1 : y2;
        final rw = (x2 - x1).abs();
        final rh = (y2 - y1).abs();
        if (rw >= 4 && rh >= 4) {
          widget.notifier.setCollisionRect(
              _collisionEditId!, rx.round(), ry.round(), rw.round(), rh.round());
          setState(() {
            _collisionEditId = null;
            _colDragStart = null;
            _colDragEnd = null;
          });
        }
        // If rect too small, keep collision mode active for a retry.
      }
      // Never call tapCanvas while in collision edit mode — it would deselect the tile.
      _draggingId = null;
      _draggingPixel = false;
      _didPan = false;
      return;
    }

    if (!_didPan) {
      final canvasPos = _toCanvas(_panStartPointer);
      final (gx, gy) = _toGrid(canvasPos);
      widget.notifier.tapCanvas(gx, gy,
          px: canvasPos.dx.round(), py: canvasPos.dy.round());
    }
    _draggingId = null;
    _draggingPixel = false;
    _didPan = false;
  }

  List<Widget> _buildSelectionOverlay(PlacedTile tile, Size availableSize) {
    final isFloor = tile.layerName == "floor";
    final sx = _offset.dx + (isFloor ? tile.x * _baseCell : tile.x.toDouble()) * _scale;
    final sy = _offset.dy + (isFloor ? tile.y * _baseCell : tile.y.toDouble()) * _scale;
    final sw = (isFloor ? tile.w * _baseCell : tile.w.toDouble()) * _scale;
    final sh = (isFloor ? tile.h * _baseCell : tile.h.toDouble()) * _scale;

    // ── Drag handle factory (move / resize) ──────────────────────────────────
    Widget dragHandle({
      required double left,
      required double top,
      required IconData icon,
      required String tooltip,
      required void Function(DragStartDetails) onPanStart,
      required void Function(DragUpdateDetails) onPanUpdate,
    }) =>
        Positioned(
          left: left,
          top: top,
          child: Tooltip(
            message: tooltip,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
                ),
                child: Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ),
          ),
        );

    // ── Collision draw mode: show draw hint + cancel ─────────────────────────
    if (_collisionEditId == tile.id) {
      return [
        // Move handle stays so tile can be repositioned
        dragHandle(
          left: sx - 10, top: sy - 10,
          icon: Icons.open_with, tooltip: "Move",
          onPanStart: (d) { _handleStartX = tile.x; _handleStartY = tile.y; _handleGlobalStart = d.globalPosition; },
          onPanUpdate: (d) {
            final delta = d.globalPosition - _handleGlobalStart;
            final newX = !isFloor ? _handleStartX + (delta.dx / _scale).round()
                                   : _handleStartX + (delta.dx / (_scale * _baseCell)).round();
            final newY = !isFloor ? _handleStartY + (delta.dy / _scale).round()
                                   : _handleStartY + (delta.dy / (_scale * _baseCell)).round();
            widget.notifier.movePlaced(tile.id, newX, newY);
          },
        ),
        // Draw-mode indicator: "+" icon at top-right
        Positioned(
          left: sx + sw - 10,
          top: sy - 10,
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
            ),
            child: const Icon(Icons.add, size: 13, color: Colors.white),
          ),
        ),
        // Bottom hint bar
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xDD1A1E2B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF9800), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 14, color: Color(0xFFFF9800)),
                  const SizedBox(width: 6),
                  const Text("Drag to draw collision area",
                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      _collisionEditId = null;
                      _colDragStart = null;
                      _colDragEnd = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF37474F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // ── Normal mode ──────────────────────────────────────────────────────────

    // "⋯" pill trigger position (top-right of tile)
    final trigL = sx + sw - 14;
    final trigT = sy - 13;

    // Popover sizing
    const menuW = 168.0;
    const menuH = 224.0; // 6 items × 34px + 16px padding

    // Auto-position: prefer right of trigger, fall back to left, then above.
    double menuL = trigL + 18;
    double menuT = trigT - 4;
    if (menuL + menuW > availableSize.width - 4) menuL = trigL - menuW - 2;
    if (menuL < 4) menuL = 4;
    if (menuT + menuH > availableSize.height - 4) menuT = availableSize.height - menuH - 4;
    if (menuT < 4) menuT = 4;

    // Action items
    void doAction(VoidCallback action) {
      setState(() => _showTileMenu = false);
      action();
    }

    final actions = <({IconData icon, String label, Color color, VoidCallback onTap})>[
      (icon: Icons.flip, label: "Mirror", color: const Color(0xFF5C6BC0),
        onTap: () => doAction(() => widget.notifier.flipPlaced(tile.id))),
      (icon: Icons.rotate_right, label: "Rotate", color: const Color(0xFF26A69A),
        onTap: () => doAction(() => widget.notifier.rotatePlaced(tile.id))),
      (icon: Icons.content_copy_outlined, label: "Duplicate", color: const Color(0xFF42A5F5),
        onTap: () => doAction(() => widget.notifier.duplicatePlaced(tile.id))),
      (icon: Icons.crop_free, label: tile.colRect != null ? "Collision ✓" : "Collision",
        color: tile.colRect != null ? const Color(0xFFFF9800) : const Color(0xFF78909C),
        onTap: () => doAction(() => setState(() {
          _collisionEditId = tile.id;
          _colDragStart = null;
          _colDragEnd = null;
        }))),
      (icon: Icons.flip_to_front_outlined, label: "Bring to Front", color: const Color(0xFF8D6E63),
        onTap: () => doAction(() => widget.notifier.bringToFront(tile.id))),
      (icon: Icons.delete_outline, label: "Delete", color: const Color(0xFFEF5350),
        onTap: () => doAction(() => widget.notifier.deletePlaced(tile.id))),
    ];

    return [
      // Move handle — top-left
      dragHandle(
        left: sx - 10, top: sy - 10,
        icon: Icons.open_with, tooltip: "Move",
        onPanStart: (d) { _handleStartX = tile.x; _handleStartY = tile.y; _handleGlobalStart = d.globalPosition; },
        onPanUpdate: (d) {
          final delta = d.globalPosition - _handleGlobalStart;
          final newX = !isFloor ? _handleStartX + (delta.dx / _scale).round()
                                 : _handleStartX + (delta.dx / (_scale * _baseCell)).round();
          final newY = !isFloor ? _handleStartY + (delta.dy / _scale).round()
                                 : _handleStartY + (delta.dy / (_scale * _baseCell)).round();
          widget.notifier.movePlaced(tile.id, newX, newY);
        },
      ),
      // Resize handle — bottom-right (non-floor only)
      if (!isFloor) dragHandle(
        left: sx + sw - 10, top: sy + sh - 10,
        icon: Icons.open_in_full, tooltip: "Resize",
        onPanStart: (d) { _resizeStartW = tile.w; _resizeStartH = tile.h; _resizeGlobalStart = d.globalPosition; },
        onPanUpdate: (d) {
          final delta = d.globalPosition - _resizeGlobalStart;
          widget.notifier.resizePlaced(tile.id,
              _resizeStartW + (delta.dx / _scale).round(),
              _resizeStartH + (delta.dy / _scale).round());
        },
      ),
      // "⋯" pill trigger
      Positioned(
        left: trigL,
        top: trigT,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _showTileMenu = !_showTileMenu),
          child: Container(
            width: 26, height: 18,
            decoration: BoxDecoration(
              color: _showTileMenu
                  ? const Color(0xFF455A64)
                  : const Color(0xFF263238),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _showTileMenu
                    ? const Color(0xFF90A4AE)
                    : const Color(0xFF546E7A),
                width: 1,
              ),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
            ),
            child: const Center(
              child: Text("···",
                  style: TextStyle(color: Colors.white, fontSize: 11, height: 1.0,
                      letterSpacing: 1)),
            ),
          ),
        ),
      ),
      // Popover menu
      if (_showTileMenu)
        Positioned(
          left: menuL,
          top: menuT,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // absorb taps so canvas doesn't deselect
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: menuW,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2533),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF37474F), width: 1),
                  boxShadow: const [
                    BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: actions.map((a) => _menuItem(a.icon, a.label, a.color, a.onTap)).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _menuItem(IconData icon, String label, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(5)),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(color: Color(0xFFCFD8DC), fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isPainting = widget.editorState.paletteSelectedId != null;
    final isEmpty = widget.editorState.placedTiles.isEmpty;
    final selectedTile = widget.editorState.selectedTile;
    final isDrawingCollision = _collisionEditId != null;
    final cursor = isDrawingCollision
        ? SystemMouseCursors.precise
        : isPainting
            ? SystemMouseCursors.precise
            : selectedTile != null
                ? SystemMouseCursors.grab
                : SystemMouseCursors.basic;

    return MouseRegion(
      cursor: cursor,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRect(
                    child: CustomPaint(
                      painter: _CanvasPainter(
                        editorState: widget.editorState,
                        tileById: widget.tileById,
                        images: widget.images,
                        scale: _scale,
                        offset: _offset,
                        colors: widget.colors,
                        showCollision: _showCollision,
                        collisionEditId: _collisionEditId,
                        colDragStart: _colDragStart,
                        colDragEnd: _colDragEnd,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // Collision overlay toggle
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _showCollision = !_showCollision),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _showCollision
                              ? const Color(0xEEFF3333)
                              : const Color(0xBB000000),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFFFFF), width: 1),
                        ),
                        child: Text(
                          _showCollision ? "COLLISION ON" : "COLLISION",
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Selection overlay
                  if (selectedTile != null)
                    ..._buildSelectionOverlay(selectedTile, availableSize),
                  if (isEmpty && !isPainting)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_outlined,
                                  color: Color(0x33FFFFFF), size: 40),
                              SizedBox(height: 10),
                              Text(
                                "Select a component from the palette to paint",
                                style: TextStyle(
                                    color: Color(0x44FFFFFF), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (isPainting)
                    const Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Text(
                            "Click on canvas to paint  •  ESC to cancel",
                            style: TextStyle(
                                color: Color(0x66FFFFFF), fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _CanvasPainter extends CustomPainter {
  const _CanvasPainter({
    required this.editorState,
    required this.tileById,
    required this.images,
    required this.scale,
    required this.offset,
    required this.colors,
    this.showCollision = false,
    this.collisionEditId,
    this.colDragStart,
    this.colDragEnd,
  });

  final MapEditorData editorState;
  final Map<String, ScenaryTile> tileById;
  final Map<String, ui.Image> images;
  final double scale;
  final Offset offset;
  final AppColors colors;
  final bool showCollision;
  final String? collisionEditId;
  final Offset? colDragStart;
  final Offset? colDragEnd;

  static const _cell = 32.0;

  // BoxFit.contain: scale src proportionally to fit inside dst, centered
  static Rect _containFit(double srcW, double srcH, Rect dst) {
    final srcAspect = srcW / srcH;
    final dstAspect = dst.width / dst.height;
    double w, h;
    if (srcAspect > dstAspect) {
      w = dst.width;
      h = dst.width / srcAspect;
    } else {
      h = dst.height;
      w = dst.height * srcAspect;
    }
    return Rect.fromCenter(center: dst.center, width: w, height: h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final mapW = editorState.width * _cell;
    final mapH = editorState.height * _cell;

    // Background — always dark for the editor canvas
    canvas.drawRect(
      Rect.fromLTWH(0, 0, mapW, mapH),
      Paint()..color = const Color(0xFF1E2533),
    );

    final imgPaint = Paint()..filterQuality = FilterQuality.medium;
    final placedTiles = editorState.placedTiles;

    // Render in layer order: floor → walls (+ overlays) → objects
    for (final layerName in ["floor", "walls", "objects"]) {
      for (final pt in placedTiles.values) {
        if (pt.layerName != layerName) continue;
        _drawPlaced(canvas, pt, imgPaint);

        // Draw overlay on walls
        if (layerName == "walls" && pt.overlayId != null) {
          _drawOverlay(canvas, pt, imgPaint);
        }
      }
    }

    // Grid lines — subtle on dark background
    final linePaint = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 0.5 / scale;

    for (var x = 0; x <= editorState.width; x++) {
      canvas.drawLine(
          Offset(x * _cell, 0), Offset(x * _cell, mapH), linePaint);
    }
    for (var y = 0; y <= editorState.height; y++) {
      canvas.drawLine(
          Offset(0, y * _cell), Offset(mapW, y * _cell), linePaint);
    }

    // Map border — accent line to mark the map boundary
    canvas.drawRect(
      Rect.fromLTWH(0, 0, mapW, mapH),
      Paint()
        ..color = const Color(0xFF3D5068)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / scale,
    );

    // Collision overlay — drawn before selection so selection stays on top
    if (showCollision) _drawCollisionOverlay(canvas);

    // Collision draw preview (drag rect)
    if (collisionEditId != null && colDragStart != null && colDragEnd != null) {
      final x1 = colDragStart!.dx; final y1 = colDragStart!.dy;
      final x2 = colDragEnd!.dx;   final y2 = colDragEnd!.dy;
      final previewRect = Rect.fromLTRB(
        x1 < x2 ? x1 : x2, y1 < y2 ? y1 : y2,
        x1 < x2 ? x2 : x1, y1 < y2 ? y2 : y1,
      );
      canvas.drawRect(previewRect, Paint()..color = const Color(0x88FF9800));
      canvas.drawRect(previewRect, Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / scale);
    }

    // Selection highlight (always on top)
    final sel = editorState.selectedTile;
    if (sel != null) _drawSelection(canvas, sel);

    canvas.restore();
  }

  void _drawCollisionOverlay(Canvas canvas) {
    final passPaint  = Paint()..color = const Color(0x9922FF88);
    final customPaint = Paint()..color = const Color(0xBBFF9800);
    final border = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / scale;
    final customBorder = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale;

    for (final pt in editorState.placedTiles.values) {
      final def = tileById[pt.tileId];
      if (def == null) continue;

      final isFloor = pt.layerName == "floor";
      final Rect fullRect = isFloor
          ? Rect.fromLTWH(pt.x * _cell, pt.y * _cell, pt.w * _cell, pt.h * _cell)
          : Rect.fromLTWH(pt.x.toDouble(), pt.y.toDouble(), pt.w.toDouble(), pt.h.toDouble());

      // If tile has a custom colRect, show it in orange (overrides default).
      if (pt.colRect != null) {
        final cr = pt.colRect!;
        final crRect = Rect.fromLTWH(
          cr.x.toDouble(), cr.y.toDouble(), cr.w.toDouble(), cr.h.toDouble());
        canvas.drawRect(fullRect, Paint()..color = const Color(0x33FF9800));
        canvas.drawRect(crRect, customPaint);
        canvas.drawRect(crRect, customBorder);
        continue;
      }

      // Doors/portals are passable (green).
      if (def.category == "door") {
        canvas.drawRect(fullRect, passPaint);
        canvas.drawRect(fullRect, border);
      }
    }
  }

  void _drawPlaced(Canvas canvas, PlacedTile pt, Paint imgPaint) {
    final img = images[pt.tileId];
    final tileDef = tileById[pt.tileId];
    final cols = tileDef?.frameCols ?? 1;
    final rows = tileDef?.frameRows ?? 1;
    final category = tileDef?.category ?? "";

    // Floor: grid cell coordinates. Everything else: pixel coordinates.
    final fullRect = pt.layerName == "floor"
        ? Rect.fromLTWH(pt.x * _cell, pt.y * _cell, pt.w * _cell, pt.h * _cell)
        : Rect.fromLTWH(pt.x.toDouble(), pt.y.toDouble(), pt.w.toDouble(), pt.h.toDouble());

    if (img != null) {
      final frameW = img.width / cols;
      final frameH = img.height / rows;
      final src = Rect.fromLTWH(
          pt.frameCol * frameW, pt.frameRow * frameH, frameW, frameH);

      // Walls, doors and windows keep their natural proportions (contain-fit).
      // Floor and furniture fill the cell entirely.
      final rect = (category == "wall" ||
              category == "door" ||
              category == "window")
          ? _containFit(frameW, frameH, fullRect)
          : fullRect;

      if (pt.rotation != 0 || pt.flipX) {
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        if (pt.rotation != 0) canvas.rotate(pt.rotation * pi / 180);
        if (pt.flipX) canvas.scale(-1.0, 1.0);
        canvas.drawImageRect(
          img,
          src,
          Rect.fromCenter(
              center: Offset.zero, width: rect.width, height: rect.height),
          imgPaint,
        );
        canvas.restore();
      } else {
        canvas.drawImageRect(img, src, rect, imgPaint);
      }
    } else {
      canvas.drawRect(
        fullRect,
        Paint()..color = const Color(0xFF2A3347),
      );
      // Tile ID label for unloaded images
      final textPainter = TextPainter(
        text: TextSpan(
          text: pt.tileId.substring(0, pt.tileId.length.clamp(0, 6)),
          style: TextStyle(color: const Color(0x88FFFFFF), fontSize: 6 / scale.clamp(0.5, 2.0)),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: fullRect.width);
      textPainter.paint(canvas, fullRect.topLeft + const Offset(2, 2));
    }
  }

  void _drawOverlay(Canvas canvas, PlacedTile pt, Paint imgPaint) {
    final overlayImg = images[pt.overlayId!];
    if (overlayImg == null) return;
    final rect =
        Rect.fromLTWH(pt.x * _cell, pt.y * _cell, pt.w * _cell, pt.h * _cell);
    final src = Rect.fromLTWH(
        0, 0, overlayImg.width.toDouble(), overlayImg.height.toDouble());
    canvas.drawImageRect(overlayImg, src, rect, imgPaint);
  }

  void _drawSelection(Canvas canvas, PlacedTile sel) {
    final rect = sel.layerName == "floor"
        ? Rect.fromLTWH(sel.x * _cell, sel.y * _cell, sel.w * _cell, sel.h * _cell)
        : Rect.fromLTWH(sel.x.toDouble(), sel.y.toDouble(), sel.w.toDouble(), sel.h.toDouble());
    final stroke = 2.0 / scale;
    canvas.drawRect(
      rect.deflate(stroke / 2),
      Paint()
        ..color = colors.brandPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final h = 5.0 / scale;
    final hPaint = Paint()..color = colors.brandPrimary;
    for (final c in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawRect(
          Rect.fromCenter(center: c, width: h, height: h), hPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) =>
      old.editorState.placedTiles != editorState.placedTiles ||
      old.editorState.selectedId != editorState.selectedId ||
      old.scale != scale ||
      old.offset != offset ||
      old.images != images ||
      old.showCollision != showCollision ||
      old.collisionEditId != collisionEditId ||
      old.colDragStart != colDragStart ||
      old.colDragEnd != colDragEnd;
}
