import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_spacing.dart";
import "../../../shared/design_system/design_system.dart";
import "../../auth/presentation/auth_provider.dart";
import "../../avatar/presentation/character_provider.dart";
import "../../avatar/presentation/presence_provider.dart";
import "game/office_canvas.dart";
import "workspace_provider.dart";

class OfficePage extends ConsumerWidget {
  const OfficePage({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final user = ref.watch(authProvider).user;
    final characterId = ref.watch(characterProvider);
    final displayName = user?.displayName ?? "Você";
    final role = ref.watch(orgRoleProvider);
    final canEditMap = role == "owner" || role == "admin";
    final status = ref.watch(userStatusProvider);
    final catalog = ref.watch(statusCatalogProvider).valueOrNull;
    final dotColor = presenceColor(
        colors, catalog?.presenceById(status.presenceId)?.colorKey ?? "");

    return Scaffold(
      backgroundColor: colors.app,
      body: Stack(
        children: [
          Positioned.fill(
            child: OfficeCanvas(
              characterId: characterId,
              displayName: displayName,
              workspaceId: workspaceId,
              token: ref.watch(authProvider).token ?? "",
              canToggleCollision: canEditMap,
              presenceDotColor: dotColor,
              statusEmoji: status.emoji,
            ),
          ),
          Positioned(
            top: AppSpacing.xl,
            left: AppSpacing.xl,
            child: AppPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back,
                    tooltip: "Voltar",
                    onPressed: () =>
                        context.goNamed(AppRouteNames.characterSelection),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Escritório",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(child: _StatusMenu()),
          ),
        ],
      ),
    );
  }
}

// ─── Status menu ─────────────────────────────────────────────────────────────

class _StatusMenu extends ConsumerStatefulWidget {
  const _StatusMenu();

  @override
  ConsumerState<_StatusMenu> createState() => _StatusMenuState();
}

class _StatusMenuState extends ConsumerState<_StatusMenu> {
  bool _open = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _applyText() {
    ref.read(userStatusProvider.notifier).update(
        (s) => s.copyWith(customText: _textController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = ref.watch(userStatusProvider);
    final notifier = ref.read(userStatusProvider.notifier);
    final catalog = ref.watch(statusCatalogProvider).valueOrNull;
    if (catalog == null) return const SizedBox.shrink();

    final currentPresence = catalog.presenceById(status.presenceId);
    final currentColor =
        presenceColor(colors, currentPresence?.colorKey ?? "");

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded panel
        if (_open)
          Container(
            width: 300,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.panel.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x44000000), blurRadius: 16),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Presence options (from the status catalog asset)
                ...catalog.presences.map((opt) {
                  final selected = status.presenceId == opt.id;
                  return InkWell(
                    onTap: () => notifier
                        .update((s) => s.copyWith(presenceId: opt.id)),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.brandPrimary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: presenceColor(colors, opt.colorKey),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            Icon(Icons.check,
                                size: 15, color: colors.brandPrimary),
                        ],
                      ),
                    ),
                  );
                }),

                Divider(color: colors.border, height: AppSpacing.lg),

                // Emoji quick picks
                Text(
                  "EMOJI",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: catalog.quickEmojis.map((e) {
                    final selected = status.emoji == e;
                    return InkWell(
                      onTap: () => notifier.update((s) => selected
                          ? s.copyWith(clearEmoji: true)
                          : s.copyWith(emoji: e)),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.brandPrimary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: selected
                                ? colors.brandPrimary
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                            child:
                                Text(e, style: const TextStyle(fontSize: 16))),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.md),

                // Manual status text
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: TextField(
                          controller: _textController,
                          onSubmitted: (_) => _applyText(),
                          style: TextStyle(
                              fontSize: 12, color: colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Status personalizado...",
                            hintStyle: TextStyle(
                                fontSize: 12, color: colors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppIconButton(
                      icon: Icons.check,
                      tooltip: "Aplicar",
                      onPressed: _applyText,
                    ),
                  ],
                ),

                if (status.customText != null || status.emoji != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _textController.clear();
                        notifier.update((s) =>
                            s.copyWith(clearEmoji: true, clearText: true));
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        "Limpar status",
                        style: TextStyle(
                            fontSize: 11, color: colors.textMuted),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Collapsed pill
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.panel.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: _open ? colors.brandPrimary : colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                if (status.emoji != null) ...[
                  Text(status.emoji!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                ],
                Text(
                  status.labelWith(catalog),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _open ? Icons.expand_more : Icons.expand_less,
                  size: 16,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
