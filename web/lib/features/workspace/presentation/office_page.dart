import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_spacing.dart";
import "../../../shared/design_system/design_system.dart";
import "../../auth/presentation/auth_provider.dart";
import "../../avatar/presentation/character_provider.dart";
import "game/office_canvas.dart";

class OfficePage extends ConsumerWidget {
  const OfficePage({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final user = ref.watch(authProvider).user;
    final characterId = ref.watch(characterProvider);
    final displayName = user?.displayName ?? "Você";

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
          Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: colors.panel.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  "Use WASD ou ← ↑ → ↓ para mover",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
