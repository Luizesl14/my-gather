import "package:flutter/material.dart";

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.app,
    required this.panel,
    required this.panelMuted,
    required this.toolbar,
    required this.tooltip,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.border,
    required this.borderStrong,
    required this.focus,
    required this.brandPrimary,
    required this.brandPrimaryHover,
    required this.brandSecondary,
    required this.cyan,
    required this.green,
    required this.yellow,
    required this.orange,
    required this.red,
    required this.purple,
    required this.presenceAvailable,
    required this.presenceAway,
    required this.presenceBusy,
    required this.presenceMeeting,
    required this.presenceFocus,
    required this.presenceOffline,
  });

  final Color canvas;
  final Color app;
  final Color panel;
  final Color panelMuted;
  final Color toolbar;
  final Color tooltip;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;
  final Color border;
  final Color borderStrong;
  final Color focus;
  final Color brandPrimary;
  final Color brandPrimaryHover;
  final Color brandSecondary;
  final Color cyan;
  final Color green;
  final Color yellow;
  final Color orange;
  final Color red;
  final Color purple;
  final Color presenceAvailable;
  final Color presenceAway;
  final Color presenceBusy;
  final Color presenceMeeting;
  final Color presenceFocus;
  final Color presenceOffline;

  static const light = AppColors(
    canvas: Color(0xFFF3F6FA),
    app: Color(0xFFEEF3F8),
    panel: Color(0xFFFFFFFF),
    panelMuted: Color(0xFFF7F9FC),
    toolbar: Color(0xFFD8E1EC),
    tooltip: Color(0xFF111827),
    textPrimary: Color(0xFF172033),
    textSecondary: Color(0xFF4B5870),
    textMuted: Color(0xFF7A869A),
    textInverse: Color(0xFFFFFFFF),
    border: Color(0xFFC7D2E1),
    borderStrong: Color(0xFF8EA0B8),
    focus: Color(0xFF4267D6),
    brandPrimary: Color(0xFF4267D6),
    brandPrimaryHover: Color(0xFF3657BA),
    brandSecondary: Color(0xFF6D5BD7),
    cyan: Color(0xFF39A9DB),
    green: Color(0xFF35A85A),
    yellow: Color(0xFFF2C94C),
    orange: Color(0xFFF2994A),
    red: Color(0xFFE5484D),
    purple: Color(0xFF8B5CF6),
    presenceAvailable: Color(0xFF35A85A),
    presenceAway: Color(0xFFF2C94C),
    presenceBusy: Color(0xFFE5484D),
    presenceMeeting: Color(0xFF4267D6),
    presenceFocus: Color(0xFF8B5CF6),
    presenceOffline: Color(0xFF9AA3B2),
  );

  static const dark = AppColors(
    canvas: Color(0xFF111827),
    app: Color(0xFF0D1320),
    panel: Color(0xFF1B2433),
    panelMuted: Color(0xFF253143),
    toolbar: Color(0xFF2B3A50),
    tooltip: Color(0xFFF8FAFC),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    textInverse: Color(0xFF111827),
    border: Color(0xFF344256),
    borderStrong: Color(0xFF53647D),
    focus: Color(0xFF7DA2FF),
    brandPrimary: Color(0xFF7DA2FF),
    brandPrimaryHover: Color(0xFFA8BEFF),
    brandSecondary: Color(0xFFA78BFA),
    cyan: Color(0xFF67D8FF),
    green: Color(0xFF55C978),
    yellow: Color(0xFFF6D365),
    orange: Color(0xFFFFB066),
    red: Color(0xFFFF6B70),
    purple: Color(0xFFB69CFF),
    presenceAvailable: Color(0xFF55C978),
    presenceAway: Color(0xFFF6D365),
    presenceBusy: Color(0xFFFF6B70),
    presenceMeeting: Color(0xFF7DA2FF),
    presenceFocus: Color(0xFFB69CFF),
    presenceOffline: Color(0xFF64748B),
  );

  @override
  AppColors copyWith({
    Color? canvas,
    Color? app,
    Color? panel,
    Color? panelMuted,
    Color? toolbar,
    Color? tooltip,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? border,
    Color? borderStrong,
    Color? focus,
    Color? brandPrimary,
    Color? brandPrimaryHover,
    Color? brandSecondary,
    Color? cyan,
    Color? green,
    Color? yellow,
    Color? orange,
    Color? red,
    Color? purple,
    Color? presenceAvailable,
    Color? presenceAway,
    Color? presenceBusy,
    Color? presenceMeeting,
    Color? presenceFocus,
    Color? presenceOffline,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      app: app ?? this.app,
      panel: panel ?? this.panel,
      panelMuted: panelMuted ?? this.panelMuted,
      toolbar: toolbar ?? this.toolbar,
      tooltip: tooltip ?? this.tooltip,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      focus: focus ?? this.focus,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandPrimaryHover: brandPrimaryHover ?? this.brandPrimaryHover,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      cyan: cyan ?? this.cyan,
      green: green ?? this.green,
      yellow: yellow ?? this.yellow,
      orange: orange ?? this.orange,
      red: red ?? this.red,
      purple: purple ?? this.purple,
      presenceAvailable: presenceAvailable ?? this.presenceAvailable,
      presenceAway: presenceAway ?? this.presenceAway,
      presenceBusy: presenceBusy ?? this.presenceBusy,
      presenceMeeting: presenceMeeting ?? this.presenceMeeting,
      presenceFocus: presenceFocus ?? this.presenceFocus,
      presenceOffline: presenceOffline ?? this.presenceOffline,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      app: Color.lerp(app, other.app, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelMuted: Color.lerp(panelMuted, other.panelMuted, t)!,
      toolbar: Color.lerp(toolbar, other.toolbar, t)!,
      tooltip: Color.lerp(tooltip, other.tooltip, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandPrimaryHover:
          Color.lerp(brandPrimaryHover, other.brandPrimaryHover, t)!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      green: Color.lerp(green, other.green, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      red: Color.lerp(red, other.red, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      presenceAvailable:
          Color.lerp(presenceAvailable, other.presenceAvailable, t)!,
      presenceAway: Color.lerp(presenceAway, other.presenceAway, t)!,
      presenceBusy: Color.lerp(presenceBusy, other.presenceBusy, t)!,
      presenceMeeting: Color.lerp(presenceMeeting, other.presenceMeeting, t)!,
      presenceFocus: Color.lerp(presenceFocus, other.presenceFocus, t)!,
      presenceOffline: Color.lerp(presenceOffline, other.presenceOffline, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
