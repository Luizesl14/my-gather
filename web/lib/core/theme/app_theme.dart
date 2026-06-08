import "package:flutter/material.dart";

import "app_colors.dart";
import "app_radius.dart";
import "app_typography.dart";

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brandPrimary,
      onPrimary: colors.textInverse,
      secondary: colors.brandSecondary,
      onSecondary: colors.textInverse,
      error: colors.red,
      onError: colors.textInverse,
      surface: colors.panel,
      onSurface: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.canvas,
      textTheme:
          AppTypography.textTheme(colors.textPrimary, colors.textSecondary),
      extensions: const <ThemeExtension<dynamic>>[
        AppColors.light,
      ],
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          fixedSize: const Size.square(36),
          minimumSize: const Size.square(36),
          shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.buttonBorder),
          foregroundColor: colors.textPrimary,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 150),
        exitDuration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: colors.tooltip,
          borderRadius: AppRadius.buttonBorder,
        ),
        textStyle: TextStyle(
          color: colors.textInverse,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.panel,
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadius.modalBorder),
      ),
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[
        colors,
      ],
    );
  }
}
