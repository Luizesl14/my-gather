import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../avatar/domain/avatar_direction.dart";
import "../../avatar/domain/avatar_motion_state.dart";
import "../../avatar/domain/avatar_position.dart";

class RemoteAvatar {
  const RemoteAvatar({
    required this.userId,
    required this.displayName,
    required this.characterId,
    required this.position,
    required this.direction,
    required this.motionState,
    this.presenceStatus = "available",
  });

  final String userId;
  final String displayName;
  final String characterId;
  final AvatarPosition position;
  final AvatarDirection direction;
  final AvatarMotionState motionState;
  final String presenceStatus;

  RemoteAvatar copyWith({
    AvatarPosition? position,
    AvatarDirection? direction,
    AvatarMotionState? motionState,
    String? presenceStatus,
  }) =>
      RemoteAvatar(
        userId: userId,
        displayName: displayName,
        characterId: characterId,
        position: position ?? this.position,
        direction: direction ?? this.direction,
        motionState: motionState ?? this.motionState,
        presenceStatus: presenceStatus ?? this.presenceStatus,
      );
}

class RemoteAvatarsNotifier extends Notifier<Map<String, RemoteAvatar>> {
  @override
  Map<String, RemoteAvatar> build() => const {};

  void handleEvent(Map<String, dynamic> event) {
    final type = event["type"] as String?;

    switch (type) {
      case "workspace:roster":
        final users = (event["users"] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        state = {
          for (final u in users) u["userId"] as String: _fromMap(u),
        };

      case "workspace:user.joined":
        final userId = event["userId"] as String? ?? "";
        if (userId.isEmpty) return;
        state = {...state, userId: _fromMap(event, key: "userId")};

      case "workspace:user.left":
        final userId = event["userId"] as String? ?? "";
        final next = Map<String, RemoteAvatar>.from(state);
        next.remove(userId);
        state = next;

      case "avatar:moved":
        final userId = event["userId"] as String? ?? "";
        final existing = state[userId];
        if (existing == null) return;
        state = {
          ...state,
          userId: existing.copyWith(
            position: AvatarPosition(
              x: (event["x"] as num).toDouble(),
              y: (event["y"] as num).toDouble(),
            ),
            direction: avatarDirectionFromString(event["direction"] as String? ?? "front"),
            motionState: (event["motionState"] as String?) == "walking"
                ? AvatarMotionState.walking
                : AvatarMotionState.idle,
          ),
        };

      case "presence:status.changed":
        final userId = event["userId"] as String? ?? "";
        final existing = state[userId];
        if (existing == null) return;
        state = {
          ...state,
          userId: existing.copyWith(presenceStatus: event["status"] as String? ?? "available"),
        };
    }
  }

  void clear() => state = const {};

  static RemoteAvatar _fromMap(Map<String, dynamic> m, {String key = "userId"}) {
    return RemoteAvatar(
      userId: m[key] as String? ?? m["userId"] as String? ?? "",
      displayName: m["displayName"] as String? ?? "?",
      characterId: m["characterId"] as String? ?? "character-01",
      position: AvatarPosition(
        x: (m["x"] as num?)?.toDouble() ?? 1.0,
        y: (m["y"] as num?)?.toDouble() ?? 1.0,
      ),
      direction: avatarDirectionFromString(m["direction"] as String? ?? "front"),
      motionState: (m["motionState"] as String?) == "walking"
          ? AvatarMotionState.walking
          : AvatarMotionState.idle,
      presenceStatus: m["presenceStatus"] as String? ?? "available",
    );
  }
}

final remoteAvatarsProvider =
    NotifierProvider<RemoteAvatarsNotifier, Map<String, RemoteAvatar>>(
        RemoteAvatarsNotifier.new);
