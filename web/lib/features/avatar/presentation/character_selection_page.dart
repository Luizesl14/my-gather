import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../auth/data/auth_service.dart";
import "../../auth/presentation/auth_provider.dart";
import "../data/avatar_catalog_loader.dart";
import "../domain/avatar_catalog.dart";
import "../domain/avatar_character.dart";
import "character_provider.dart";

// ─── Providers ────────────────────────────────────────────────────────────────

// Not autoDispose: catalog is an immutable asset loaded once per session.
final _catalogProvider =
    FutureProvider<AvatarCatalog>((ref) => AvatarCatalogLoader.loadDefault());

// ─── Page ─────────────────────────────────────────────────────────────────────

class CharacterSelectionPage extends ConsumerStatefulWidget {
  const CharacterSelectionPage({super.key});

  @override
  ConsumerState<CharacterSelectionPage> createState() =>
      _CharacterSelectionPageState();
}

class _CharacterSelectionPageState
    extends ConsumerState<CharacterSelectionPage> {
  CharacterCategory _category = CharacterCategory.man;
  AvatarCharacter? _selectedChar;
  bool _isEntering = false;

  void _selectCategory(CharacterCategory cat) => setState(() {
        _category = cat;
        if (_selectedChar?.category != cat) _selectedChar = null;
      });

  void _selectChar(AvatarCharacter ch) => setState(() => _selectedChar = ch);

  Future<void> _enter() async {
    final ch = _selectedChar;
    if (ch == null || _isEntering) return;
    setState(() => _isEntering = true);

    ref.read(characterProvider.notifier).state = ch.id;

    final token = ref.read(authProvider).token ?? "";
    AuthService().updateAvatar(token, ch.id).catchError((_) {});

    if (mounted) context.goNamed(AppRouteNames.workspaceSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final catalogAsync = ref.watch(_catalogProvider);

    return Scaffold(
      backgroundColor: colors.app,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 640),
          child: catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text("Erro ao carregar personagens")),
            data: (catalog) => _buildShell(context, colors, catalog),
          ),
        ),
      ),
    );
  }

  // ─── Shell ─────────────────────────────────────────────────────────────────

  Widget _buildShell(
    BuildContext context,
    AppColors colors,
    AvatarCatalog catalog,
  ) {
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
                  _PreviewPanel(
                    selectedChar: _selectedChar,
                    colors: colors,
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: colors.border),
                  Expanded(
                    child: _CharacterPanel(
                      catalog: catalog,
                      category: _category,
                      selectedChar: _selectedChar,
                      colors: colors,
                      onCategoryChanged: _selectCategory,
                      onCharSelected: _selectChar,
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppColors colors) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.panelMuted,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: [colors.brandSecondary, colors.brandPrimary],
            ).createShader(b),
            child: const Text(
              "Love+Robot",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Escolha seu personagem",
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(AppColors colors) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colors.panelMuted,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            "Você pode alterar seu personagem depois",
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed:
                _selectedChar != null && !_isEntering ? () => _enter() : null,
            icon: _isEntering
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text("Entrar"),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Left preview panel ───────────────────────────────────────────────────────

const double _kNewCharNativeH = 186.0;
const double _kNewCharNativeW = 90.0;

class _PreviewPanel extends StatefulWidget {
  const _PreviewPanel({
    required this.selectedChar,
    required this.colors,
  });

  final AvatarCharacter? selectedChar;
  final AppColors colors;

  @override
  State<_PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<_PreviewPanel> {
  Timer? _timer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_PreviewPanel old) {
    super.didUpdateWidget(old);
    if (old.selectedChar?.id != widget.selectedChar?.id) {
      _frame = 0;
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = null;
    final frames = widget.selectedChar?.frames.walkDown;
    if (frames == null || frames.isEmpty || !mounted) return;
    _timer = Timer.periodic(const Duration(milliseconds: 125), (_) {
      if (mounted) setState(() => _frame = (_frame + 1) % frames.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.selectedChar;
    final colors = widget.colors;

    final walkFrames = ch?.frames.walkDown ?? [];
    final framePath = ch != null
        ? (walkFrames.isNotEmpty
            ? walkFrames[_frame % walkFrames.length]
            : ch.frames.idleFront)
        : null;

    final isLegacy = ch != null && !ch.frames.idleFront.startsWith("normal/");

    return Container(
      width: 200,
      color: colors.panelMuted,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 160,
            child: ch != null && framePath != null
                ? _buildPreview(framePath, isLegacy, colors)
                : _placeholder(colors),
          ),
          const SizedBox(height: 12),
          if (ch != null) ...[
            Text(
              ch.displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (ch.type == "special")
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Especial",
                    style: TextStyle(
                      color: colors.brandPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ] else
            Text(
              "Nenhum\nselecionado",
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview(String framePath, bool isLegacy, AppColors colors) {
    const containerW = 120.0, containerH = 160.0;
    const charScale = containerH / _kNewCharNativeH;
    const charDisplayW = _kNewCharNativeW * charScale;
    const charLeft = (containerW - charDisplayW) / 2;

    if (isLegacy) {
      return Image.asset(
        "assets/sprites/characters/$framePath",
        width: containerW,
        fit: BoxFit.fitWidth,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _placeholder(colors),
      );
    }

    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            left: charLeft,
            top: 0,
            child: SizedBox(
              width: charDisplayW,
              height: containerH,
              child: Image.asset(
                "assets/sprites/characters/$framePath",
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => _placeholder(colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(AppColors colors) => Icon(
        Icons.person_outline_rounded,
        size: 72,
        color: colors.border,
      );
}

// ─── Character panel ──────────────────────────────────────────────────────────

class _CharacterPanel extends StatelessWidget {
  const _CharacterPanel({
    required this.catalog,
    required this.category,
    required this.selectedChar,
    required this.colors,
    required this.onCategoryChanged,
    required this.onCharSelected,
  });

  final AvatarCatalog catalog;
  final CharacterCategory category;
  final AvatarCharacter? selectedChar;
  final AppColors colors;
  final ValueChanged<CharacterCategory> onCategoryChanged;
  final ValueChanged<AvatarCharacter> onCharSelected;

  static const _cats = [
    (CharacterCategory.man, "Personagens"),
    (CharacterCategory.special, "Especiais"),
  ];

  @override
  Widget build(BuildContext context) {
    final chars =
        catalog.characters.where((c) => c.category == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: _cats.map((c) {
              final (cat, label) = c;
              final sel = cat == category;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel
                          ? colors.brandPrimary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? colors.brandPrimary : colors.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: sel
                            ? colors.brandPrimary
                            : colors.textSecondary,
                        fontWeight:
                            sel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: chars.isEmpty
              ? Center(
                  child: Text(
                    "Nenhum personagem",
                    style: TextStyle(color: colors.textMuted),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: chars.length,
                  itemBuilder: (ctx, i) {
                    final ch = chars[i];
                    return _Thumb(
                      imagePath:
                          "assets/sprites/characters/${ch.frames.idleFront}",
                      label: ch.displayName,
                      selected: selectedChar?.id == ch.id,
                      colors: colors,
                      onTap: () => onCharSelected(ch),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Shared thumbnail ─────────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.imagePath,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String imagePath;
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  bool get _isLegacy => !imagePath.contains("/normal/");

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: selected
              ? colors.brandPrimary.withValues(alpha: 0.10)
              : colors.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colors.brandPrimary : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                child: ClipRect(
                  child: LayoutBuilder(
                    builder: (ctx, box) {
                      final imgH = box.maxHeight;
                      final imgW = box.maxWidth;
                      const charScale = 1.0 / _kNewCharNativeH;
                      final charDisplayW = _kNewCharNativeW * imgH * charScale;
                      final charLeft = (imgW - charDisplayW) / 2;

                      if (_isLegacy) {
                        return Image.asset(
                          imagePath,
                          width: imgW,
                          fit: BoxFit.fitWidth,
                          filterQuality: FilterQuality.none,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: colors.border,
                            size: 28,
                          ),
                        );
                      }

                      return Stack(
                        children: [
                          Positioned(
                            left: charLeft,
                            top: 0,
                            child: SizedBox(
                              width: charDisplayW,
                              height: imgH,
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  color: colors.border,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? colors.brandPrimary : colors.textMuted,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
