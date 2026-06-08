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

  AvatarViewModel get avatar => _avatar;

  bool move(AvatarDirection direction) {
    final (dx, dy) = switch (direction) {
      AvatarDirection.front => (0.0, _step),
      AvatarDirection.back  => (0.0, -_step),
      AvatarDirection.left  => (-_step, 0.0),
      AvatarDirection.right => (_step, 0.0),
    };
    final next = _avatar.position.moveBy(dx, dy);

    // Collision uses floor() — character occupies the tile it stands in.
    if (!_map.canOccupyTile(next.tileX, next.tileY)) {
      return false;
    }

    _avatar = _avatar.copyWith(
      position: next,
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
