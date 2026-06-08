import "package:flutter/material.dart";

import "../../core/theme/app_colors.dart";
import "../../core/theme/app_radius.dart";
import "../../core/theme/app_spacing.dart";

class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.brandPrimary,
        borderRadius: AppRadius.buttonBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textInverse,
              ),
        ),
      ),
    );
  }
}
