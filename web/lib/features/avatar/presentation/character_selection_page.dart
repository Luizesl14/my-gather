import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../auth/data/auth_service.dart";
import "../../auth/presentation/auth_provider.dart";
import "../data/avatar_catalog_loader.dart";
import "../domain/avatar_character.dart";
import "character_provider.dart";

final _catalogProvider = FutureProvider.autoDispose<List<AvatarCharacter>>((ref) async {
  final catalog = await AvatarCatalogLoader.loadDefault();
  return catalog.characters;
});

class CharacterSelectionPage extends ConsumerStatefulWidget {
  const CharacterSelectionPage({super.key});

  @override
  ConsumerState<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends ConsumerState<CharacterSelectionPage> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.52, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _prev(int total) { if (_index > 0) _goto(_index - 1); }
  void _next(int total) { if (_index < total - 1) _goto(_index + 1); }

  void _goto(int i) {
    setState(() => _index = i);
    _pageController.animateToPage(i,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _enter(List<AvatarCharacter> characters) async {
    final ch = characters[_index];
    ref.read(characterProvider.notifier).state = ch.id;
    final token = ref.read(authProvider).token ?? "";
    try { await AuthService().updateAvatar(token, ch.id); } catch (_) {}
    if (mounted) {
      context.goNamed(AppRouteNames.workspaceSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = ref.watch(authProvider).user;
    final catalogAsync = ref.watch(_catalogProvider);

    return Scaffold(
      backgroundColor: colors.app,
      body: SafeArea(
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text("Erro ao carregar personagens")),
          data: (characters) => _buildContent(context, colors, user?.displayName ?? "", characters),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppColors colors,
    String displayName,
    List<AvatarCharacter> characters,
  ) {
    final safeIndex = _index.clamp(0, characters.length - 1);
    final ch = characters[safeIndex];

    return Column(
      children: [

        // ── Header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(children: [
            ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: [colors.brandSecondary, colors.brandPrimary],
              ).createShader(b),
              child: Text("Love+Robot",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Text("Escolha seu personagem",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              "Olá${displayName.isNotEmpty ? ', $displayName' : ''}! "
              "Como você quer aparecer no escritório?",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center),
          ]),
        ),

        // ── Carrossel + Nome + Controles ──────────────────────────
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: characters.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final isCenter = i == safeIndex;
                      final info = characters[i];
                      return Center(
                        child: GestureDetector(
                          onTap: () => _goto(i),
                          child: AnimatedScale(
                            scale: isCenter ? 1.0 : 0.80,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                            child: AnimatedOpacity(
                              opacity: isCenter ? 1.0 : 0.38,
                              duration: const Duration(milliseconds: 260),
                              child: SizedBox(
                                width: 156,
                                height: 240,
                                child: _CharacterCard(info: info, isSelected: isCenter, colors: colors),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(ch.id),
                    children: [
                      Text(ch.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ArrowButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: safeIndex > 0,
                      colors: colors,
                      onTap: () => _prev(characters.length),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(characters.length, (i) {
                      final active = i == safeIndex;
                      return GestureDetector(
                        onTap: () => _goto(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? colors.brandPrimary : colors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    _ArrowButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: safeIndex < characters.length - 1,
                      colors: colors,
                      onTap: () => _next(characters.length),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),

        // ── Footer ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Você poderá mudar depois",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              FilledButton.icon(
                onPressed: () => _enter(characters),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text("Entrar no escritório"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              ),
            ],
          ),
        ),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.info, required this.isSelected, required this.colors});
  final AvatarCharacter info;
  final bool isSelected;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? colors.brandPrimary.withValues(alpha: 0.07) : colors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? colors.brandPrimary : colors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: colors.brandPrimary.withValues(alpha: 0.20), blurRadius: 20, spreadRadius: 1)]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Image.asset(
          "assets/sprites/characters/${info.id}/preview.png",
          filterQuality: FilterQuality.none,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.person, size: 48, color: colors.textMuted),
              const SizedBox(height: 8),
              Text(info.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted, fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.enabled, required this.colors, required this.onTap});
  final IconData icon;
  final bool enabled;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? colors.panel : Colors.transparent,
          border: Border.all(
            color: enabled ? colors.border : colors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: enabled ? colors.textPrimary : colors.border.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
