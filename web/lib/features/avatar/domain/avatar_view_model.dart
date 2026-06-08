import "avatar_direction.dart";
import "avatar_motion_state.dart";
import "avatar_position.dart";

class AvatarViewModel {
  const AvatarViewModel({
    required this.characterId,
    required this.displayName,
    required this.position,
    required this.direction,
    required this.motionState,
    required this.presenceLabel,
  });

  final String characterId;
  final String displayName;
  final AvatarPosition position;
  final AvatarDirection direction;
  final AvatarMotionState motionState;
  final String presenceLabel;

  AvatarViewModel copyWith({
    String? characterId,
    String? displayName,
    AvatarPosition? position,
    AvatarDirection? direction,
    AvatarMotionState? motionState,
    String? presenceLabel,
  }) {
    return AvatarViewModel(
      characterId: characterId ?? this.characterId,
      displayName: displayName ?? this.displayName,
      position: position ?? this.position,
      direction: direction ?? this.direction,
      motionState: motionState ?? this.motionState,
      presenceLabel: presenceLabel ?? this.presenceLabel,
    );
  }
}
