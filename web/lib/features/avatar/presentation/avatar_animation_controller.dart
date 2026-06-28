import "../domain/avatar_character.dart";
import "../domain/avatar_direction.dart";
import "../domain/avatar_motion_state.dart";

class AvatarAnimationController {
  AvatarAnimationController({
    required AvatarCharacter character,
    AvatarDirection direction = AvatarDirection.front,
    AvatarMotionState motionState = AvatarMotionState.idle,
  })  : _character = character,
        _direction = direction,
        _motionState = motionState;

  final AvatarCharacter _character;
  AvatarDirection _direction;
  AvatarMotionState _motionState;
  DateTime _startedAt = DateTime.now();

  AvatarDirection get direction => _direction;
  AvatarMotionState get motionState => _motionState;

  void setDirection(AvatarDirection direction) {
    if (_direction == direction) return;
    _direction = direction;
    _startedAt = DateTime.now();
  }

  void setMotionState(AvatarMotionState motionState) {
    if (_motionState == motionState) return;
    _motionState = motionState;
    _startedAt = DateTime.now();
  }

  String currentFramePath() {
    if (_motionState == AvatarMotionState.idle) {
      return switch (_direction) {
        AvatarDirection.front => _character.frames.idleFront,
        AvatarDirection.back => _character.frames.idleBack,
        AvatarDirection.left => _character.frames.idleLeft,
        AvatarDirection.right => _character.frames.idleRight,
      };
    }

    final elapsedMs = DateTime.now().difference(_startedAt).inMilliseconds;
    final frames = _walkFrames();
    final index = ((elapsedMs / _frameMs).floor()) % frames.length;
    return frames[index];
  }

  static const int _frameMs = 125;

  List<String> _walkFrames() => switch (_direction) {
        AvatarDirection.front => _character.frames.walkDown,
        AvatarDirection.back => _character.frames.walkUp,
        AvatarDirection.left => _character.frames.walkLeft,
        AvatarDirection.right => _character.frames.walkRight,
      };

  // Monotonic footfall counter while walking — two footfalls per walk cycle, so
  // the footstep sound can play in sync with the leg animation. -1 when idle.
  int get stepBeat {
    if (_motionState == AvatarMotionState.idle) return -1;
    final cycleMs = _frameMs * _walkFrames().length;
    final halfStepMs = (cycleMs / 2).round().clamp(1, cycleMs);
    final elapsedMs = DateTime.now().difference(_startedAt).inMilliseconds;
    return elapsedMs ~/ halfStepMs;
  }
}
