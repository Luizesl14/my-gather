// ignore_for_file: prefer_const_constructors

import "package:flutter_test/flutter_test.dart";

import "package:love_robot_web/features/avatar/domain/avatar_character.dart";
import "package:love_robot_web/features/avatar/domain/avatar_direction.dart";
import "package:love_robot_web/features/avatar/domain/avatar_motion_state.dart";
import "package:love_robot_web/features/avatar/domain/avatar_position.dart";
import "package:love_robot_web/features/avatar/domain/avatar_view_model.dart";
import "package:love_robot_web/features/avatar/presentation/avatar_animation_controller.dart";
import "package:love_robot_web/features/avatar/presentation/avatar_movement_controller.dart";
import "package:love_robot_web/features/workspace/presentation/game/office_map.dart";

OfficeMap _map() {
  return OfficeMap(
    id: "test-map",
    width: 3,
    height: 3,
    tileSize: 32,
    spawn: MapSpawn(x: 1, y: 1, direction: "front"),
    layers: [
      MapLayer(
        name: "floor",
        tiles: [
          MapTile(tile: "floor-office-light", x: 0, y: 0),
          MapTile(tile: "floor-office-light", x: 1, y: 0),
          MapTile(tile: "floor-office-light", x: 2, y: 0),
          MapTile(tile: "floor-office-light", x: 0, y: 1),
          MapTile(tile: "wall-office", x: 1, y: 1),
          MapTile(tile: "floor-office-light", x: 2, y: 1),
          MapTile(tile: "floor-office-light", x: 0, y: 2),
          MapTile(tile: "floor-office-light", x: 1, y: 2),
          MapTile(tile: "floor-office-light", x: 2, y: 2),
        ],
        objects: [
          MapObject(
            id: "desk-1",
            asset: "desk-wood",
            x: 2,
            y: 2,
            layer: 1,
          ),
        ],
      ),
    ],
    interactiveZones: [],
  );
}

AvatarViewModel _avatar() {
  return AvatarViewModel(
    characterId: "character-01",
    displayName: "Ada",
    position: AvatarPosition(tileX: 0, tileY: 0),
    direction: AvatarDirection.front,
    motionState: AvatarMotionState.idle,
    presenceLabel: "Disponível",
  );
}

AvatarAnimationController _animationController() {
  return AvatarAnimationController(
    character: AvatarCharacter(
      id: "character-01",
      displayName: "Ada",
      defaultCharacter: true,
      frames: AvatarCharacterFrames(
        idleFront: "idle-front.png",
        idleBack: "idle-back.png",
        idleLeft: "idle-left.png",
        idleRight: "idle-right.png",
        walkDown: ["walk-down-1.png", "walk-down-2.png"],
        walkLeft: ["walk-left-1.png", "walk-left-2.png"],
        walkRight: ["walk-right-1.png", "walk-right-2.png"],
        walkUp: ["walk-up-1.png", "walk-up-2.png"],
      ),
      hitbox: AvatarHitbox(x: 6, y: 22, width: 20, height: 24),
    ),
  );
}

void main() {
  test("mover respeita colisao e atualiza estado", () {
    final controller = AvatarMovementController(
      map: _map(),
      avatar: _avatar(),
      animationController: _animationController(),
    );

    expect(controller.move(AvatarDirection.right), isTrue);
    expect(controller.avatar.position.tileX, 1);
    expect(controller.avatar.direction, AvatarDirection.right);
    expect(controller.avatar.motionState, AvatarMotionState.walking);

    expect(controller.move(AvatarDirection.front), isFalse);
    expect(controller.avatar.position.tileX, 1);
    expect(controller.avatar.position.tileY, 0);

    controller.stop();
    expect(controller.avatar.motionState, AvatarMotionState.idle);
  });
}
