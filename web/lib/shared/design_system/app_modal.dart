import "package:flutter/material.dart";

import "../../core/theme/app_colors.dart";
import "../../core/theme/app_radius.dart";
import "../../core/theme/app_spacing.dart";

class AppModal extends StatelessWidget {
  const AppModal({
    required this.child,
    super.key,
    this.title,
  });

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.panel,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.modalBorder),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.panel),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
