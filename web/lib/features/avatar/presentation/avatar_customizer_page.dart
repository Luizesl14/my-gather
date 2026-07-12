import "dart:async";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../auth/data/auth_service.dart";
import "../../auth/presentation/auth_provider.dart";
import "../data/modular_avatar_baker.dart";
import "../data/modular_catalog_loader.dart";
import "../domain/avatar_loadout.dart";
import "avatar_loadout_provider.dart";
import "character_provider.dart";

/// Paletas de cor por slot. null nos slots sem suporte a cor.
const _slotPalettes = <String, List<String>>{
  "hair": [
    "1C1C1C", "4A2F1B", "7B4A21", "D9A441",
    "A93226", "B8B8C0", "5B7FD4", "D96BA0",
  ],
  "top": [
    "3E6FBF", "B03A3A", "3F8F4F", "D9B23F",
    "7B4FA5", "2E2E2E", "E8E8E8", "D9782F",
  ],
  "bottom": [
    "3E6FBF", "B03A3A", "3F8F4F", "D9B23F",
    "7B4FA5", "2E2E2E", "E8E8E8", "D9782F",
  ],
};

// Not autoDispose: catálogo é asset imutável, carregado uma vez por sessão.
final _modularCatalogProvider =
    FutureProvider<ModularCatalog>((ref) => ModularCatalogLoader.loadDefault());

class AvatarCustomizerPage extends ConsumerStatefulWidget {
  const AvatarCustomizerPage({super.key});

  @override
  ConsumerState<AvatarCustomizerPage> createState() =>
      _AvatarCustomizerPageState();
}

class _AvatarCustomizerPageState extends ConsumerState<AvatarCustomizerPage> {
  static const _directions = ["front", "left", "back", "right"];
  static const _directionLabels = {
    "front": "Frente",
    "left": "Esquerda",
    "back": "Costas",
    "right": "Direita",
  };

  AvatarLoadout _loadout = const AvatarLoadout(bodyId: "anime-unissex");
  int _directionIndex = 0;
  int _walkFrame = 0;
  bool _walking = true;
  bool _isSaving = false;
  Timer? _animationTimer;

  // Frames assados (camadas + cores) do loadout atual, chaveados por
  // "modular://<frame>". Reassados a cada mudança de peça/cor.
  Map<String, ui.Image>? _bakedFrames;
  int _bakeGeneration = 0;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(avatarLoadoutProvider);
    if (saved != null) _loadout = saved;
    _rebake();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (_walking && mounted) setState(() => _walkFrame = (_walkFrame + 1) % 3);
    });
  }

  Future<void> _rebake() async {
    final generation = ++_bakeGeneration;
    final frames = await ModularAvatarBaker.bake(_loadout);
    // Descarta resultados de bakes antigos que terminaram fora de ordem.
    if (mounted && generation == _bakeGeneration) {
      setState(() => _bakedFrames = frames);
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  String get _direction => _directions[_directionIndex];

  /// Nome do frame atual segundo a convenção do catálogo modular.
  String get _frameName {
    if (!_walking) return "idle-$_direction";
    const walkAxis = {
      "front": "down",
      "back": "up",
      "left": "left",
      "right": "right",
    };
    final frame = (_walkFrame + 1).toString().padLeft(2, "0");
    return "walk-${walkAxis[_direction]}-$frame";
  }

  void _rotate(int delta) => setState(() =>
      _directionIndex = (_directionIndex + delta + _directions.length) %
          _directions.length);

  void _setSlotItem(String slotId, String? itemId) {
    setState(() => _loadout = _loadout.withItem(slotId, itemId));
    _rebake();
  }

  void _setSlotColor(String slotId, String? hex) {
    setState(() => _loadout = _loadout.withColor(slotId, hex));
    _rebake();
  }

  String? _selectedItem(String slotId) => _loadout.itemFor(slotId);

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final encoded = _loadout.encode();
    ref.read(avatarLoadoutProvider.notifier).state = _loadout;
    ref.read(characterProvider.notifier).state = encoded;

    final token = ref.read(authProvider).token ?? "";
    AuthService().updateAvatar(token, encoded).catchError((_) {});

    if (mounted) context.goNamed(AppRouteNames.workspaceSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final catalogAsync = ref.watch(_modularCatalogProvider);

    return Scaffold(
      backgroundColor: colors.app,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 640),
          child: catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text("Erro ao carregar peças do avatar")),
            data: (catalog) => _buildShell(colors, catalog),
          ),
        ),
      ),
    );
  }

  Widget _buildShell(AppColors colors, ModularCatalog catalog) {
    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPreviewPanel(colors, catalog),
                  VerticalDivider(width: 1, thickness: 1, color: colors.border),
                  Expanded(child: _buildSlotsPanel(colors, catalog)),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.border),
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Text(
            "Monte seu personagem",
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.goNamed(AppRouteNames.characterPresets),
            icon: const Icon(Icons.people_outline, size: 16),
            label: const Text("Personagens prontos"),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(AppColors colors, ModularCatalog catalog) {
    final frame =
        _bakedFrames?["${ModularAvatarBaker.framePrefix}$_frameName"];
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32 * 5,
            height: 48 * 5,
            child: frame == null
                ? const Center(child: CircularProgressIndicator())
                : RawImage(
                    image: frame,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _rotate(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: "Girar",
              ),
              SizedBox(
                width: 84,
                child: Text(
                  _directionLabels[_direction]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
              IconButton(
                onPressed: () => _rotate(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: "Girar",
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => setState(() => _walking = !_walking),
            icon: Icon(_walking ? Icons.pause : Icons.directions_walk, size: 18),
            label: Text(_walking ? "Pausar" : "Andar"),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsPanel(AppColors colors, ModularCatalog catalog) {
    final customizableSlots =
        catalog.slots.where((s) => !s.required).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final slot in customizableSlots) ...[
          Text(
            slot.displayName,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _OptionCard(
                colors: colors,
                selected: _selectedItem(slot.id) == null,
                label: "Nenhum",
                child: Icon(Icons.block, color: colors.textSecondary, size: 28),
                onTap: () => _setSlotItem(slot.id, null),
              ),
              for (final item in slot.items)
                _OptionCard(
                  colors: colors,
                  selected: _selectedItem(slot.id) == item.id,
                  label: item.displayName,
                  onTap: () => _setSlotItem(slot.id, item.id),
                  child: _itemThumb(slot.id, item),
                ),
            ],
          ),
          if (_slotPalettes[slot.id] != null &&
              _selectedItem(slot.id) != null) ...[
            const SizedBox(height: 10),
            _buildColorRow(colors, slot.id),
          ],
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  /// Miniatura da peça com zoom na região que ela ocupa no frame 128x128 —
  /// sem isso, um tênis vira meia dúzia de pixels perdidos no card.
  /// scale segue a semântica do Image.asset (maior = imagem menor);
  /// alignment escolhe a faixa vertical visível dentro do recorte.
  Widget _itemThumb(String slotId, ModularItem item) {
    final (scale, alignment) = switch (slotId) {
      "hair" => (1.6, const Alignment(0, -0.9)),
      "beard" => (1.2, const Alignment(0, -0.4)),
      "top" => (1.2, const Alignment(0, 0.1)),
      "bottom" => (1.2, const Alignment(0, 0.6)),
      "shoes" => (1.0, const Alignment(0, 0.98)),
      _ => (2.7, Alignment.center), // ~equivalente ao contain antigo
    };
    return ClipRect(
      child: Image.asset(
        item.frameAsset("idle-front"),
        fit: BoxFit.none,
        scale: scale,
        alignment: alignment,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildColorRow(AppColors colors, String slotId) {
    final selected = _loadout.colorFor(slotId);
    Widget dot({String? hex}) {
      final isSelected = selected == hex;
      return InkWell(
        onTap: () => _setSlotColor(slotId, hex),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: hex == null
                ? Colors.transparent
                : Color(int.parse("FF$hex", radix: 16)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? colors.brandPrimary : colors.border,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: hex == null
              ? Icon(Icons.format_color_reset,
                  size: 14, color: colors.textSecondary)
              : null,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        dot(hex: null),
        for (final hex in _slotPalettes[slotId]!) dot(hex: hex),
      ],
    );
  }

  Widget _buildFooter(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text("Salvar e continuar"),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.colors,
    required this.selected,
    required this.label,
    required this.child,
    required this.onTap,
  });

  final AppColors colors;
  final bool selected;
  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? colors.brandPrimary.withValues(alpha: 0.12)
              : colors.app,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colors.brandPrimary : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            SizedBox(width: 64, height: 72, child: Center(child: child)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}