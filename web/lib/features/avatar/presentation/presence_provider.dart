import "dart:convert";

import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/theme/app_colors.dart";

// ─── Status catalog (loaded from assets/config/status-catalog.json) ──────────

class PresenceOption {
  const PresenceOption({
    required this.id,
    required this.label,
    required this.colorKey,
  });

  final String id;
  final String label;
  // Key resolved against AppColors presence colors (e.g. "presenceAvailable").
  final String colorKey;

  factory PresenceOption.fromJson(Map<String, dynamic> j) => PresenceOption(
        id: j["id"] as String,
        label: j["label"] as String,
        colorKey: j["color"] as String,
      );
}

class StatusCatalog {
  const StatusCatalog({required this.presences, required this.quickEmojis});

  final List<PresenceOption> presences;
  final List<String> quickEmojis;

  PresenceOption? presenceById(String id) {
    for (final p in presences) {
      if (p.id == id) return p;
    }
    return null;
  }
}

final statusCatalogProvider = FutureProvider<StatusCatalog>((ref) async {
  final text =
      await rootBundle.loadString("assets/config/status-catalog.json");
  final json = jsonDecode(text) as Map<String, dynamic>;
  return StatusCatalog(
    presences: (json["presences"] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PresenceOption.fromJson)
        .toList(growable: false),
    quickEmojis:
        (json["quickEmojis"] as List<dynamic>).cast<String>(),
  );
});

// ─── User status state ────────────────────────────────────────────────────────

class UserStatus {
  const UserStatus({
    this.presenceId = "available",
    this.emoji,
    this.customText,
  });

  final String presenceId;
  final String? emoji;
  final String? customText;

  // Label shown in the UI: manual text wins over the presence label.
  String labelWith(StatusCatalog? catalog) {
    if (customText != null && customText!.isNotEmpty) return customText!;
    return catalog?.presenceById(presenceId)?.label ?? presenceId;
  }

  UserStatus copyWith({
    String? presenceId,
    String? emoji,
    String? customText,
    bool clearEmoji = false,
    bool clearText = false,
  }) =>
      UserStatus(
        presenceId: presenceId ?? this.presenceId,
        emoji: clearEmoji ? null : (emoji ?? this.emoji),
        customText: clearText ? null : (customText ?? this.customText),
      );
}

final userStatusProvider = StateProvider<UserStatus>((ref) => const UserStatus());

// Resolves a catalog color key against the app theme. Single source of truth
// for presence colors across the status menu and the avatar name bubble.
Color presenceColor(AppColors colors, String colorKey) => switch (colorKey) {
      "presenceAvailable" => colors.presenceAvailable,
      "presenceAway" => colors.presenceAway,
      "presenceBusy" => colors.presenceBusy,
      "presenceMeeting" => colors.presenceMeeting,
      "presenceFocus" => colors.presenceFocus,
      _ => colors.presenceOffline,
    };
