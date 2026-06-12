import "../domain/avatar_direction.dart";
import "../domain/avatar_motion_state.dart";
import "../domain/avatar_position.dart";
import "../domain/avatar_view_model.dart";
import "../../workspace/presentation/game/office_map.dart";
import "avatar_animation_controller.dart";

class AvatarMovementController {
  AvatarMovementController({
    required OfficeMap map,
    required AvatarViewModel avatar,
    required AvatarAnimationController animationController,
  })  : _map = map,
        _avatar = avatar,
        _animationController = animationController;

  final OfficeMap _map;
  final AvatarAnimationController _animationController;
  AvatarViewModel _avatar;

  // Quarter-tile steps for fine-grained positioning.
  static const double _step = 0.25;
  // Smallest substep when sliding up against an obstacle: 1px (1/32 tile).
  static const double _minStep = 0.03125;

  AvatarViewModel get avatar => _avatar;

  bool move(AvatarDirection direction) {
    final (ux, uy) = switch (direction) {
      AvatarDirection.front => (0.0, 1.0),
      AvatarDirection.back  => (0.0, -1.0),
      AvatarDirection.left  => (-1.0, 0.0),
      AvatarDirection.right => (1.0, 0.0),
    };

    // Try the full step; when blocked, halve it until the avatar can slide
    // flush against the obstacle (pixel-precise contact).
    AvatarPosition? target;
    for (var step = _step; step >= _minStep; step /= 2) {
      final next = _avatar.position.moveBy(ux * step, uy * step);
      if (_map.canOccupy(next.x, next.y)) {
        target = next;
        break;
      }
    }
    if (target == null) return false;

    _avatar = _avatar.copyWith(
      position: target,
      direction: direction,
      motionState: AvatarMotionState.walking,
    );
    _animationController.setDirection(direction);
    _animationController.setMotionState(AvatarMotionState.walking);
    return true;
  }

  void stop() {
    _avatar = _avatar.copyWith(motionState: AvatarMotionState.idle);
    _animationController.setMotionState(AvatarMotionState.idle);
  }

  void setInitialPosition(AvatarPosition position, AvatarDirection direction) {
    _avatar = _avatar.copyWith(position: position, direction: direction);
    _animationController.setDirection(direction);
    _animationController.setMotionState(AvatarMotionState.idle);
  }
}
