import "package:flutter/material.dart";

import "../../core/theme/app_colors.dart";
import "../../core/theme/app_radius.dart";
import "../../core/theme/app_spacing.dart";

class AppPanel extends StatelessWidget {
  const AppPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.panel),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.panelBorder,
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
