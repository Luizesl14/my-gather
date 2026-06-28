import "dart:convert";
import "dart:math" show pi, min, max;
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
import "../../../avatar/data/avatar_catalog_loader.dart";
import "../../../avatar/domain/avatar_catalog.dart";
import "../../../avatar/domain/avatar_character.dart";
import "../../../avatar/presentation/character_provider.dart";
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

final _editorAvatarCatalogProvider =
    FutureProvider.autoDispose<AvatarCatalog>(
  (ref) => AvatarCatalogLoader.loadDefault(),
);

// ─── Page ────────────────────────────────────────────────────────────────────

class MapEditorPage extends ConsumerStatefulWidget {
  const MapEditorPage({required this.workspaceId, super.key});
  final String workspaceId;

  @override
  ConsumerState<MapEditorPage> createState() => _MapEditorPageState();
}

class _MapEditorPageState extends ConsumerState<MapEditorPage> {
  bool _showCollision = true;
  bool _paintCollision = false;
  bool _placingSpawn = false;
  bool _spaceHeld = false;
  bool _showCharOnCanvas = false;

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
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (event is KeyDownEvent && !_spaceHeld) {
            setState(() => _spaceHeld = true);
            return KeyEventResult.handled;
          }
          if (event is KeyUpEvent && _spaceHeld) {
            setState(() => _spaceHeld = false);
            return KeyEventResult.handled;
          }
        }
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Palette
                tilesAsync.when(
                  loading: () => const SizedBox(
                      width: 300,
                      child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(width: 300),
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
                      showCollision: _showCollision,
                      onToggleCollision: () =>
                          setState(() => _showCollision = !_showCollision),
                      paintCollision: _paintCollision,
                      onExitPaintCollision: () =>
                          setState(() => _paintCollision = false),
                      placingSpawn: _placingSpawn,
                      onExitPlaceSpawn: () =>
                          setState(() => _placingSpawn = false),
                      spaceHeld: _spaceHeld,
                      showCharOnCanvas: _showCharOnCanvas,
                      onToggleCharOnCanvas: () =>
                          setState(() => _showCharOnCanvas = !_showCharOnCanvas),
                    ),
                  ),
                ),
              ],
            ),
            // Floating centered toolbar
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: _FloatingToolbar(
                  editorState: editorState,
                  notifier: notifier,
                  colors: colors,
                  showCollision: _showCollision,
                  onToggleCollision: () => setState(() {
                    _showCollision = !_showCollision;
                    if (!_showCollision) _paintCollision = false;
                  }),
                  paintCollision: _paintCollision,
                  onTogglePaintCollision: () {
                    final entering = !_paintCollision;
                    setState(() {
                      _paintCollision = entering;
                      if (_paintCollision) _showCollision = true;
                    });
                    // When entering paint mode, clear tile selection so its
                    // GestureDetectors don't compete with the paint drag.
                    if (entering) {
                      ref.read(mapEditorProvider((widget.workspaceId,
                              ref.read(authProvider).token ?? ""))
                          .notifier)
                          .clearSelection();
                    }
                  },
                  placingSpawn: _placingSpawn,
                  onTogglePlaceSpawn: () {
                    final entering = !_placingSpawn;
                    setState(() {
                      _placingSpawn = entering;
                      if (entering) _paintCollision = false;
                    });
                    if (entering) {
                      ref.read(mapEditorProvider((widget.workspaceId,
                              ref.read(authProvider).token ?? ""))
                          .notifier)
                          .clearSelection();
                    }
                  },
                  showCharOnCanvas: _showCharOnCanvas,
                  onToggleCharOnCanvas: () =>
                      setState(() => _showCharOnCanvas = !_showCharOnCanvas),
                  onBack: () =>
                      context.goNamed(AppRouteNames.workspaceSelection),
                  onSaveResult: (msg) =>
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Floating toolbar ────────────────────────────────────────────────────────

class _FloatingToolbar extends StatelessWidget {
  const _FloatingToolbar({
    required this.editorState,
    required this.notifier,
    required this.colors,
    required this.showCollision,
    required this.onToggleCollision,
    required this.paintCollision,
    required this.onTogglePaintCollision,
    required this.placingSpawn,
    required this.onTogglePlaceSpawn,
    required this.showCharOnCanvas,
    required this.onToggleCharOnCanvas,
    required this.onBack,
    required this.onSaveResult,
  });

  final MapEditorData editorState;
  final MapEditorNotifier notifier;
  final AppColors colors;
  final bool showCollision;
  final VoidCallback onToggleCollision;
  final bool paintCollision;
  final VoidCallback onTogglePaintCollision;
  final bool placingSpawn;
  final VoidCallback onTogglePlaceSpawn;
  final bool showCharOnCanvas;
  final VoidCallback onToggleCharOnCanvas;
  final VoidCallback onBack;
  final void Function(String) onSaveResult;

  static const _btnPad =
      EdgeInsets.symmetric(horizontal: 14, vertical: 9);
  static const _btnStyle =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
  static const _btnMinSize = Size(0, 40);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.panel.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Voltar ──
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 15),
              label: const Text("Voltar"),
              style: OutlinedButton.styleFrom(
                padding: _btnPad,
                minimumSize: _btnMinSize,
                textStyle: _btnStyle,
              ),
            ),
            _FTDivider(colors: colors),
            // ── Limpar ──
            Tooltip(
              message: "Limpar tudo",
              child: OutlinedButton(
                onPressed: notifier.clearAll,
                style: OutlinedButton.styleFrom(
                  padding: _btnPad,
                  minimumSize: _btnMinSize,
                  textStyle: _btnStyle,
                ),
                child: Icon(Icons.delete_sweep_outlined,
                    size: 16, color: colors.textSecondary),
              ),
            ),
            const SizedBox(width: 4),
            // ── Mapa ──
            _MapSizeButton(
                editorState: editorState, notifier: notifier, colors: colors),
            const SizedBox(width: 4),
            // ── Personagem ──
            _CharacterConfigButton(
              editorState: editorState,
              notifier: notifier,
              colors: colors,
              onShowChar: () {
                if (!showCharOnCanvas) onToggleCharOnCanvas();
              },
            ),
            const SizedBox(width: 4),
            // ── Ver personagem no mapa ──
            Tooltip(
              message: showCharOnCanvas
                  ? "Ocultar personagem no mapa"
                  : "Ver personagem no mapa",
              child: OutlinedButton.icon(
                onPressed: onToggleCharOnCanvas,
                icon: Icon(
                  showCharOnCanvas ? Icons.visibility_off : Icons.visibility,
                  size: 15,
                ),
                label: const Text("No mapa"),
                style: OutlinedButton.styleFrom(
                  padding: _btnPad,
                  minimumSize: _btnMinSize,
                  textStyle: _btnStyle,
                  foregroundColor: showCharOnCanvas
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  side: showCharOnCanvas
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // ── Colisão ──
            Tooltip(
              message: showCollision
                  ? "Ocultar áreas de colisão"
                  : "Mostrar áreas de colisão",
              child: OutlinedButton.icon(
                onPressed: onToggleCollision,
                icon: Icon(
                  showCollision ? Icons.grid_on : Icons.grid_off,
                  size: 15,
                ),
                label: const Text("Colisão"),
                style: OutlinedButton.styleFrom(
                  padding: _btnPad,
                  minimumSize: _btnMinSize,
                  textStyle: _btnStyle,
                  foregroundColor: showCollision
                      ? const Color(0xFFFF9800)
                      : null,
                  side: showCollision
                      ? const BorderSide(color: Color(0xFFFF9800))
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // ── Pintar colisão ──
            Tooltip(
              message: paintCollision
                  ? "Sair do modo pincel"
                  : "Pintar colisão livremente",
              child: OutlinedButton.icon(
                onPressed: onTogglePaintCollision,
                icon: Icon(
                  paintCollision ? Icons.edit_off : Icons.edit_rounded,
                  size: 15,
                ),
                label: const Text("Pintar"),
                style: OutlinedButton.styleFrom(
                  padding: _btnPad,
                  minimumSize: _btnMinSize,
                  textStyle: _btnStyle,
                  foregroundColor: paintCollision
                      ? const Color(0xFFFF9800)
                      : null,
                  side: paintCollision
                      ? const BorderSide(color: Color(0xFFFF9800))
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // ── Ponto de spawn ──
            Tooltip(
              message: placingSpawn
                  ? "Clique no mapa para definir o spawn"
                  : "Definir onde os personagens nascem",
              child: OutlinedButton.icon(
                onPressed: onTogglePlaceSpawn,
                icon: Icon(
                  placingSpawn ? Icons.location_on : Icons.location_on_outlined,
                  size: 15,
                ),
                label: const Text("Spawn"),
                style: OutlinedButton.styleFrom(
                  padding: _btnPad,
                  minimumSize: _btnMinSize,
                  textStyle: _btnStyle,
                  foregroundColor: placingSpawn ? const Color(0xFF42A5F5) : null,
                  side: placingSpawn
                      ? const BorderSide(color: Color(0xFF42A5F5))
                      : null,
                ),
              ),
            ),
            _FTDivider(colors: colors),
            // ── Dirty dot ──
            if (editorState.isDirty)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: colors.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            // ── Salvar ──
            FilledButton.icon(
              onPressed: editorState.isSaving
                  ? null
                  : () async {
                      try {
                        await notifier.save();
                        onSaveResult("Mapa salvo!");
                      } catch (e) {
                        onSaveResult("Erro ao salvar: ${extractApiError(e)}");
                      }
                    },
              icon: editorState.isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 15),
              label: const Text("Salvar"),
              style: FilledButton.styleFrom(
                padding: _btnPad,
                minimumSize: _btnMinSize,
                textStyle: _btnStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FTDivider extends StatelessWidget {
  const _FTDivider({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: colors.border,
      );
}

// ─── Character config button ─────────────────────────────────────────────────

class _CharacterConfigButton extends ConsumerWidget {
  const _CharacterConfigButton({
    required this.editorState,
    required this.notifier,
    required this.colors,
    this.onShowChar,
  });

  final MapEditorData editorState;
  final MapEditorNotifier notifier;
  final AppColors colors;
  final VoidCallback? onShowChar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterId = ref.watch(characterProvider);
    final catalogAsync = ref.watch(_editorAvatarCatalogProvider);

    return Tooltip(
      message: "Configurar personagem",
      child: OutlinedButton.icon(
        onPressed: () {
          final catalog = catalogAsync.valueOrNull;
          if (catalog == null) return;
          final character = catalog.characters.firstWhere(
            (c) => c.id == characterId,
            orElse: () => catalog.characters.first,
          );
          onShowChar?.call();
          showDialog<void>(
            context: context,
            builder: (ctx) => _CharacterConfigDialog(
              character: character,
              editorState: editorState,
              notifier: notifier,
              colors: colors,
            ),
          );
        },
        icon: const Icon(Icons.person_rounded, size: 15),
        label: const Text("Personagem"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          minimumSize: const Size(0, 40),
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CharacterConfigDialog extends StatefulWidget {
  const _CharacterConfigDialog({
    required this.character,
    required this.editorState,
    required this.notifier,
    required this.colors,
  });

  final AvatarCharacter character;
  final MapEditorData editorState;
  final MapEditorNotifier notifier;
  final AppColors colors;

  @override
  State<_CharacterConfigDialog> createState() => _CharacterConfigDialogState();
}

class _CharacterConfigDialogState extends State<_CharacterConfigDialog> {
  // Original values to revert on cancel
  late double _origScale;
  late double _origYOffset;
  late double _origXOffset;

  late double _scale;
  late double _yOffset;
  late double _xOffset;

  @override
  void initState() {
    super.initState();
    _origScale = widget.editorState.avatarScale;
    _origYOffset = widget.editorState.avatarYOffset;
    _origXOffset = widget.editorState.avatarXOffset;
    _scale = _origScale;
    _yOffset = _origYOffset;
    _xOffset = _origXOffset;
  }

  void _apply() {
    widget.notifier.setAvatarScale(_scale);
    widget.notifier.setAvatarYOffset(_yOffset);
    widget.notifier.setAvatarXOffset(_xOffset);
  }

  String _fmtOffset(double v) =>
      v == 0 ? "Padrão" : v > 0 ? "+${(v * 100).round()}%" : "${(v * 100).round()}%";

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_rounded, size: 18, color: primary),
          const SizedBox(width: 8),
          Text("Personagem: ${widget.character.displayName}"),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ative \"No mapa\" no toolbar para ver as alterações em tempo real no cenário.",
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 20),
            // ── Altura ──
            Text("Altura  ${(_scale * 100).round()}%",
                style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Text("−", style: TextStyle(fontSize: 14, color: colors.textMuted)),
              Expanded(
                child: Slider(
                  value: _scale,
                  min: 0.25,
                  max: 1.2,
                  divisions: 19,
                  label: "${(_scale * 100).round()}%",
                  onChanged: (v) {
                    setState(() => _scale = v);
                    _apply();
                  },
                ),
              ),
              Text("+", style: TextStyle(fontSize: 14, color: colors.textMuted)),
            ]),
            const SizedBox(height: 12),
            // ── Vertical ──
            Text("Vertical  ${_fmtOffset(_yOffset)}",
                style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Text("↓", style: TextStyle(fontSize: 14, color: colors.textMuted)),
              Expanded(
                child: Slider(
                  value: _yOffset,
                  min: -0.6,
                  max: 0.6,
                  divisions: 24,
                  label: _fmtOffset(_yOffset),
                  onChanged: (v) {
                    setState(() => _yOffset = v);
                    _apply();
                  },
                ),
              ),
              Text("↑", style: TextStyle(fontSize: 14, color: colors.textMuted)),
            ]),
            const SizedBox(height: 12),
            // ── Horizontal ──
            Text("Horizontal  ${_fmtOffset(_xOffset)}",
                style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Text("←", style: TextStyle(fontSize: 14, color: colors.textMuted)),
              Expanded(
                child: Slider(
                  value: _xOffset,
                  min: -0.6,
                  max: 0.6,
                  divisions: 24,
                  label: _fmtOffset(_xOffset),
                  onChanged: (v) {
                    setState(() => _xOffset = v);
                    _apply();
                  },
                ),
              ),
              Text("→", style: TextStyle(fontSize: 14, color: colors.textMuted)),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.notifier.setAvatarScale(_origScale);
            widget.notifier.setAvatarYOffset(_origYOffset);
            widget.notifier.setAvatarXOffset(_origXOffset);
            Navigator.of(context).pop();
          },
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _scale = 0.5;
              _yOffset = 0.0;
              _xOffset = 0.0;
            });
            _apply();
          },
          child: const Text("Resetar"),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Aplicar"),
        ),
      ],
    );
  }
}

// ─── Map size button ──────────────────────────────────────────────────────────

class _MapSizeButton extends StatelessWidget {
  const _MapSizeButton({
    required this.editorState,
    required this.notifier,
    required this.colors,
  });

  final MapEditorData editorState;
  final MapEditorNotifier notifier;
  final AppColors colors;

  static const _presets = [
    ("Pequeno", 20, 15),
    ("Médio", 40, 30),
    ("Grande", 60, 45),
    ("Extremo", 100, 80),
  ];

  static const _zoomOptions = [1.5, 2.0, 2.5, 3.0];
  static const _zoomLabels = ["Afastado", "Padrão", "Próximo", "Imersivo"];

  static const _avatarOptions = [
    (0.35, "Micro"),
    (0.5, "Padrão"),
    (0.7, "Médio"),
    (0.9, "Grande"),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // Find current preset name for the button label.
    String presetLabel = "${editorState.width}×${editorState.height}";
    for (final (label, pw, ph) in _presets) {
      if (editorState.width == pw && editorState.height == ph) {
        presetLabel = label;
        break;
      }
    }

    return Tooltip(
      message: "Configurar mapa",
      child: OutlinedButton.icon(
        onPressed: () {
          int selW = editorState.width;
          int selH = editorState.height;
          double selZoom = editorState.displayZoom;
          double selAvatar = editorState.avatarScale;

          showDialog<void>(
            context: context,
            builder: (ctx) => StatefulBuilder(
              builder: (ctx, setS) => AlertDialog(
                title: const Text("Configurações do mapa"),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Tamanho ──
                      Text("Tamanho",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary)),
                      const SizedBox(height: 12),
                      Row(
                        children: _presets.map((p) {
                          final (label, pw, ph) = p;
                          final isSel = selW == pw && selH == ph;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setS(() { selW = pw; selH = ph; }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? primary : colors.border,
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isSel
                                            ? primary
                                            : colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "$pw×$ph",
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: colors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      // ── Zoom ──
                      Text("Zoom de exibição",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        "Zoom que todos veem ao entrar no espaço.",
                        style: TextStyle(
                            fontSize: 11, color: colors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(_zoomOptions.length, (i) {
                          final z = _zoomOptions[i];
                          final isSel = selZoom == z;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setS(() => selZoom = z),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? primary : colors.border,
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text("${z}×",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isSel
                                              ? primary
                                              : colors.textPrimary,
                                        )),
                                    Text(_zoomLabels[i],
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: colors.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 22),
                      // ── Personagem ──
                      Text("Tamanho do personagem",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary)),
                      const SizedBox(height: 10),
                      Row(
                        children: _avatarOptions.map((opt) {
                          final (scale, label) = opt;
                          final isSel = selAvatar == scale;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setS(() => selAvatar = scale),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? primary : colors.border,
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: isSel
                                        ? primary
                                        : colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("Cancelar"),
                  ),
                  FilledButton(
                    onPressed: () {
                      notifier.resizeMap(selW, selH);
                      notifier.setDisplayZoom(selZoom);
                      notifier.setAvatarScale(selAvatar);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text("Aplicar"),
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.tune_rounded, size: 15),
        label: Text(presetLabel),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          minimumSize: const Size(0, 40),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
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
      width: 300,
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
            crossAxisCount: 5,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
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
                          tile.imagePath,
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

class _EditorCanvas extends ConsumerStatefulWidget {
  const _EditorCanvas({
    required this.editorState,
    required this.tileById,
    required this.images,
    required this.notifier,
    required this.colors,
    required this.showCollision,
    required this.onToggleCollision,
    required this.paintCollision,
    required this.onExitPaintCollision,
    required this.placingSpawn,
    required this.onExitPlaceSpawn,
    required this.spaceHeld,
    required this.showCharOnCanvas,
    required this.onToggleCharOnCanvas,
  });

  final MapEditorData editorState;
  final Map<String, ScenaryTile> tileById;
  final Map<String, ui.Image> images;
  final MapEditorNotifier notifier;
  final AppColors colors;
  final bool showCollision;
  final VoidCallback onToggleCollision;
  final bool paintCollision;
  final VoidCallback onExitPaintCollision;
  final bool placingSpawn;
  final VoidCallback onExitPlaceSpawn;
  final bool spaceHeld;
  final bool showCharOnCanvas;
  final VoidCallback onToggleCharOnCanvas;

  @override
  ConsumerState<_EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends ConsumerState<_EditorCanvas> {
  static const _baseCell = 32.0;
  static const _tapThreshold = 8.0;

  double _scale = 1.5;
  Offset _offset = const Offset(40, 40);

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

  // Freehand paint-collision mode
  bool? _paintErasing;          // true=erase, false=paint, null=not started
  final Set<String> _paintedIds = {}; // tiles already toggled in this stroke

  // Scroll batching — accumulate wheel events within one frame
  double _pendingScrollFactor = 1.0;
  Offset? _pendingScrollFocal;
  bool _scrollScheduled = false;

  // Character overlay
  ui.Image? _charImage;
  String? _loadedCharId;

  Size _viewportSize = Size.zero;
  bool _didInitFit = false;

  Offset _toCanvas(Offset screen) => (screen - _offset) / _scale;

  (int, int) _toGrid(Offset canvas) => (
        (canvas.dx / _baseCell).floor(),
        (canvas.dy / _baseCell).floor(),
      );

  // Returns the inner rect that fits src into dst while preserving aspect ratio.
  static Rect _containFit(double srcW, double srcH, Rect dst) {
    final sa = srcW / srcH;
    final da = dst.width / dst.height;
    final double w, h;
    if (sa > da) { w = dst.width; h = dst.width / sa; }
    else          { h = dst.height; w = dst.height * sa; }
    return Rect.fromLTWH(dst.left + (dst.width - w) / 2,
                         dst.top + (dst.height - h) / 2, w, h);
  }

  void _applyZoom(double factor) {
    final newScale = (_scale * factor).clamp(0.25, 4.0);
    if (newScale == _scale) return;
    final focal = _viewportSize == Size.zero
        ? Offset.zero
        : Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    setState(() {
      _offset = _clampOffset(focal - (focal - _offset) * (newScale / _scale));
      _scale = newScale;
    });
  }

  void _fitMap(Size viewport) {
    if (!mounted) return;
    final mapW = widget.editorState.width * _baseCell;
    final mapH = widget.editorState.height * _baseCell;
    const margin = 32.0;
    final scaleX = (viewport.width - margin * 2) / mapW;
    final scaleY = (viewport.height - margin * 2) / mapH;
    final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.25, 2.0);
    final offsetX = (viewport.width - mapW * fitScale) / 2;
    final offsetY = (viewport.height - mapH * fitScale) / 2;
    setState(() {
      _scale = fitScale;
      _offset = Offset(offsetX, offsetY);
      _didInitFit = true;
    });
  }

  Offset _clampOffset(Offset o) {
    if (_viewportSize == Size.zero) return o;
    final mapW = widget.editorState.width * _baseCell * _scale;
    final mapH = widget.editorState.height * _baseCell * _scale;
    const margin = 16.0;
    // When the map is smaller than the viewport, lo > hi which throws in Dart.
    // Use min/max to always produce valid clamp bounds.
    final loX = _viewportSize.width - mapW - margin;
    final loY = _viewportSize.height - mapH - margin;
    return Offset(
      o.dx.clamp(min(loX, margin), max(loX, margin)),
      o.dy.clamp(min(loY, margin), max(loY, margin)),
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    // Accumulate all wheel events that arrive within the same frame and
    // apply them in a single setState — avoids stacking clamp errors when
    // many events fire faster than rebuilds complete.
    _pendingScrollFactor *= event.scrollDelta.dy > 0 ? 0.9 : 1.1;
    _pendingScrollFocal ??= event.localPosition;
    if (!_scrollScheduled) {
      _scrollScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _flushScroll());
    }
  }

  void _flushScroll() {
    _scrollScheduled = false;
    if (!mounted) return;
    final factor = _pendingScrollFactor;
    final focal = _pendingScrollFocal;
    _pendingScrollFactor = 1.0;
    _pendingScrollFocal = null;
    if (focal == null) return;
    final newScale = (_scale * factor).clamp(0.25, 4.0);
    final canvasFocal = _toCanvas(focal);
    setState(() {
      _scale = newScale;
      _offset = _clampOffset(
          focal - Offset(canvasFocal.dx * newScale, canvasFocal.dy * newScale));
    });
  }

  // Returns the topmost non-floor tile (wall/object layer) at canvas position.
  PlacedTile? _hitNonFloor(Offset canvasPos) {
    PlacedTile? hit;
    for (final t in widget.editorState.placedTiles.values) {
      if (t.layerName == "floor") continue;
      if (canvasPos.dx >= t.x &&
          canvasPos.dx < t.x + t.w &&
          canvasPos.dy >= t.y &&
          canvasPos.dy < t.y + t.h) {
        hit = t;
      }
    }
    return hit;
  }

  void _applyPaintCollision(Offset localPos) {
    final cp = _toCanvas(localPos);
    final tile = _hitNonFloor(cp);
    if (tile == null || _paintedIds.contains(tile.id)) return;
    _paintedIds.add(tile.id);

    // Determine paint/erase on first touch of the stroke.
    _paintErasing ??= tile.colRects.isNotEmpty;

    if (_paintErasing!) {
      widget.notifier.clearCollisionRects(tile.id);
    } else {
      widget.notifier.setFullCollisionRect(
          tile.id, tile.x, tile.y, tile.w, tile.h);
    }
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

    // Spawn placement: a tap sets the spawn; never set up tile drag.
    if (widget.placingSpawn) return;

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
        _offset = _clampOffset(focal -
            Offset(canvasFocal.dx * newScale, canvasFocal.dy * newScale));
      });
    } else {
      final delta = details.localFocalPoint - _panStartPointer;
      if (delta.distance > _tapThreshold) _didPan = true;
      setState(() => _offset = _clampOffset(_panStartOffset + delta));
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
          widget.notifier.addCollisionRect(
              _collisionEditId!, rx.round(), ry.round(), rw.round(), rh.round());
          // Stay in collision draw mode so several rects can be drawn on the
          // same object — the user exits via the "Concluir" button.
          setState(() {
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
      // Spawn placement mode: a tap sets where players appear, then exits.
      if (widget.placingSpawn) {
        widget.notifier.setSpawn(gx, gy);
        widget.onExitPlaceSpawn();
      } else {
        widget.notifier.tapCanvas(gx, gy,
            px: canvasPos.dx.round(), py: canvasPos.dy.round());
      }
    }
    _draggingId = null;
    _draggingPixel = false;
    _didPan = false;
  }

  List<Widget> _buildSelectionOverlay(PlacedTile tile, Size availableSize) {
    final isFloor = tile.layerName == "floor";
    // Full tile bounding box in screen coords
    final fullSx = _offset.dx + (isFloor ? tile.x * _baseCell : tile.x.toDouble()) * _scale;
    final fullSy = _offset.dy + (isFloor ? tile.y * _baseCell : tile.y.toDouble()) * _scale;
    final fullSw = (isFloor ? tile.w * _baseCell : tile.w.toDouble()) * _scale;
    final fullSh = (isFloor ? tile.h * _baseCell : tile.h.toDouble()) * _scale;

    // For wall/door/window: shrink selection to the actual rendered (containFit) rect.
    // This makes the selection border match the visible image instead of the empty bounding box.
    final tileDef = widget.tileById[tile.tileId];
    final category = tileDef?.category ?? "";
    final img = widget.images[tile.tileId];
    final double sx, sy, sw, sh;
    if (!isFloor &&
        img != null &&
        (category == "wall" || category == "door" || category == "window")) {
      final fitted = _containFit(
        img.width.toDouble(), img.height.toDouble(),
        Rect.fromLTWH(0, 0, fullSw, fullSh),
      );
      sx = fullSx + fitted.left;
      sy = fullSy + fitted.top;
      sw = fitted.width;
      sh = fitted.height;
    } else {
      sx = fullSx; sy = fullSy; sw = fullSw; sh = fullSh;
    }

    // ── Drag handle factory (move / resize) ──────────────────────────────────
    Widget dragHandle({
      required double left,
      required double top,
      required IconData icon,
      required String tooltip,
      required void Function(DragStartDetails) onPanStart,
      required void Function(DragUpdateDetails) onPanUpdate,
      VoidCallback? onTap,
      MouseCursor cursor = SystemMouseCursors.grab,
      Color? handleColor,
    }) =>
        Positioned(
          left: left,
          top: top,
          child: MouseRegion(
            cursor: cursor,
            child: Tooltip(
              message: tooltip,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                onPanStart: onPanStart,
                onPanUpdate: onPanUpdate,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: handleColor ?? const Color(0xFF37474F),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
                  ),
                  child: Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.85)),
                ),
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
                  Text("Arraste para desenhar — ${tile.colRects.length} área(s)",
                      style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.notifier.removeLastCollisionRect(tile.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF37474F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("Desfazer",
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.notifier.clearCollisionRects(tile.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D4037),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("Limpar",
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("Concluir",
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

    // Action items
    final actions = <({IconData icon, String label, Color color, VoidCallback onTap})>[
      (icon: Icons.flip, label: "Espelhar", color: const Color(0xFF5C6BC0),
        onTap: () => widget.notifier.flipPlaced(tile.id)),
      (icon: Icons.rotate_right, label: "Girar", color: const Color(0xFF26A69A),
        onTap: () => widget.notifier.rotatePlaced(tile.id)),
      (icon: Icons.content_copy_outlined, label: "Duplicar", color: const Color(0xFF42A5F5),
        onTap: () => widget.notifier.duplicatePlaced(tile.id)),
      (icon: Icons.crop_free,
        label: tile.colRects.isNotEmpty ? "Colisão (${tile.colRects.length})" : "Colisão",
        color: tile.colRects.isNotEmpty ? const Color(0xFFFF9800) : const Color(0xFF78909C),
        onTap: () => setState(() {
          _collisionEditId = tile.id;
          _colDragStart = null;
          _colDragEnd = null;
        })),
      (icon: Icons.flip_to_front_outlined, label: "Frente", color: const Color(0xFF8D6E63),
        onTap: () => widget.notifier.bringToFront(tile.id)),
      (icon: Icons.delete_outline, label: "Deletar", color: const Color(0xFFEF5350),
        onTap: () => widget.notifier.deletePlaced(tile.id)),
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
        icon: Icons.aspect_ratio,
        tooltip: "Arraste para redimensionar",
        cursor: SystemMouseCursors.resizeDownRight,
        handleColor: const Color(0xFF1565C0),
        onPanStart: (d) { _resizeStartW = tile.w; _resizeStartH = tile.h; _resizeGlobalStart = d.globalPosition; },
        onPanUpdate: (d) {
          final delta = d.globalPosition - _resizeGlobalStart;
          widget.notifier.resizePlaced(tile.id,
              _resizeStartW + (delta.dx / _scale).round(),
              _resizeStartH + (delta.dy / _scale).round());
        },
      ),
      // Action bar — centered below the tile
      Positioned(
        left: (sx + sw / 2 - (actions.length * 30) / 2).clamp(4, availableSize.width - actions.length * 30 - 4),
        top: (sy + sh + 6).clamp(4, availableSize.height - 40),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // absorb taps
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xEE1E2533),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF37474F)),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: actions.map((a) => Tooltip(
                message: a.label,
                child: InkWell(
                  onTap: a.onTap,
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(a.icon, size: 14, color: a.color),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
    ];
  }


  void _loadCharImage(String charId, AvatarCatalog catalog) {
    if (_loadedCharId == charId) return;
    _loadedCharId = charId;
    final character = catalog.characters.firstWhere(
      (c) => c.id == charId,
      orElse: () => catalog.characters.first,
    );
    final path =
        "assets/sprites/characters/${character.frames.idleFront}";
    rootBundle.load(path).then((data) async {
      final codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _charImage = frame.image);
    }).catchError((_) {});
  }

  List<Widget> _buildCharacterOverlay(String charId, AvatarCatalog? catalog) {
    if (catalog != null) _loadCharImage(charId, catalog);

    final ts = _baseCell * _scale;
    final screenX = 1 * ts + _offset.dx;
    final screenY = 1 * ts + _offset.dy;

    final avatarScale = widget.editorState.avatarScale;
    final avatarYOffset = widget.editorState.avatarYOffset;
    final avatarXOffset = widget.editorState.avatarXOffset;

    final img = _charImage;
    final double spriteW, spriteH;

    if (img != null) {
      final targetH = ts * avatarScale;
      final srcW = img.width.toDouble();
      final srcH = img.height.toDouble();
      spriteW = srcW * (targetH / srcH);
      spriteH = targetH;
    } else {
      spriteW = ts * avatarScale * 0.67;
      spriteH = ts * avatarScale;
    }
    final spriteLeft = screenX - spriteW / 2 + ts / 2 + ts * avatarXOffset;
    final spriteTop = screenY - spriteH + ts - ts * avatarYOffset;

    return [
      // Label above sprite
      Positioned(
        left: spriteLeft,
        top: spriteTop - 26,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xCC1E2533),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Personagem  ${(avatarScale * 100).round()}%",
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ),
      // Character sprite
      Positioned(
        left: spriteLeft,
        top: spriteTop,
        width: spriteW,
        height: spriteH,
        child: IgnorePointer(
          child: img != null
              ? CustomPaint(painter: _CharSpritePainter(image: img))
              : Container(
                  decoration: BoxDecoration(
                    color: const Color(0x66FFFFFF),
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final charId = ref.watch(characterProvider);
    final charCatalog = ref.watch(_editorAvatarCatalogProvider).valueOrNull;

    final isPainting = widget.editorState.paletteSelectedId != null;
    final isEmpty = widget.editorState.placedTiles.isEmpty;
    final selectedTile = widget.editorState.selectedTile;
    final isDrawingCollision = _collisionEditId != null;
    final cursor = widget.paintCollision
        ? SystemMouseCursors.precise
        : isDrawingCollision
            ? SystemMouseCursors.precise
            : isPainting
                ? SystemMouseCursors.precise
                : (widget.spaceHeld || selectedTile != null)
                    ? SystemMouseCursors.grab
                    : SystemMouseCursors.basic;

    return MouseRegion(
      cursor: cursor,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableSize = Size(constraints.maxWidth, constraints.maxHeight);
            if (!_didInitFit && availableSize.width > 0 && availableSize.height > 0) {
              _viewportSize = availableSize;
              WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap(availableSize));
            }
            if (_viewportSize != availableSize && availableSize.width > 0) {
              _viewportSize = availableSize;
            }
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
                        showCollision: widget.showCollision,
                        collisionEditId: _collisionEditId,
                        colDragStart: _colDragStart,
                        colDragEnd: _colDragEnd,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // Selection overlay — hidden in paint-collision mode to avoid
                  // inner GestureDetectors competing with paint drag events.
                  if (selectedTile != null && !widget.paintCollision)
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
                  // Paint-collision mode hint
                  if (widget.paintCollision)
                    Positioned(
                      bottom: 70,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xDD1A1E2B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFFF9800)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 14,
                                    color: Color(0xFFFF9800)),
                                SizedBox(width: 8),
                                Text(
                                  "Modo pincel — arraste para pintar colisão",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Character on canvas overlay
                  if (widget.showCharOnCanvas)
                    ..._buildCharacterOverlay(charId, charCatalog),
                  // Paint-collision capture layer — uses Listener (not GestureDetector)
                  // so it bypasses the gesture arena and always wins over inner widgets.
                  if (widget.paintCollision)
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (e) {
                          _paintErasing = null;
                          _paintedIds.clear();
                          _applyPaintCollision(e.localPosition);
                        },
                        onPointerMove: (e) =>
                            _applyPaintCollision(e.localPosition),
                        onPointerUp: (_) {
                          _paintErasing = null;
                          _paintedIds.clear();
                        },
                      ),
                    ),
                  // Zoom control overlay
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _ZoomControl(
                      scale: _scale,
                      onZoomIn: () => _applyZoom(1.25),
                      onZoomOut: () => _applyZoom(1 / 1.25),
                      onReset: _fitMap,
                      viewportSize: _viewportSize,
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

// ─── Zoom control overlay ────────────────────────────────────────────────────

class _ZoomControl extends StatelessWidget {
  const _ZoomControl({
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.viewportSize,
  });

  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final void Function(Size) onReset;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC1E2533),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3D5068)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Icon(Icons.pan_tool_rounded, size: 13, color: Color(0xFF90A4AE)),
          ),
          const SizedBox(width: 2),
          _ZoomBtn(icon: Icons.remove, onTap: onZoomOut),
          GestureDetector(
            onTap: () => onReset(viewportSize),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "${(scale * 100).round()}%",
                style: const TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _ZoomBtn(icon: Icons.add, onTap: onZoomIn),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14, color: const Color(0xFF90A4AE)),
      ),
    );
  }
}

// ─── Character sprite painter ────────────────────────────────────────────────

class _CharSpritePainter extends CustomPainter {
  const _CharSpritePainter({required this.image});
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
          0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_CharSpritePainter old) => old.image != image;
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

    // Spawn point marker — where players appear when entering the office.
    final spawnRect = Rect.fromLTWH(
        editorState.spawnX * _cell, editorState.spawnY * _cell, _cell, _cell);
    canvas.drawRect(spawnRect, Paint()..color = const Color(0x5542A5F5));
    canvas.drawRect(
        spawnRect,
        Paint()
          ..color = const Color(0xFF42A5F5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / scale);
    canvas.drawCircle(
        spawnRect.center, _cell * 0.18, Paint()..color = const Color(0xFF42A5F5));

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

      // If tile has custom colRects, show them in orange (overrides default).
      if (pt.colRects.isNotEmpty) {
        canvas.drawRect(fullRect, Paint()..color = const Color(0x33FF9800));
        for (final cr in pt.colRects) {
          final crRect = Rect.fromLTWH(
            cr.x.toDouble(), cr.y.toDouble(), cr.w.toDouble(), cr.h.toDouble());
          canvas.drawRect(crRect, customPaint);
          canvas.drawRect(crRect, customBorder);
        }
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
