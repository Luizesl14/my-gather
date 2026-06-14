import "dart:ui" as ui;

import "package:flutter/services.dart";

import "../domain/avatar_catalog.dart";
import "../domain/avatar_character.dart";
import "../domain/avatar_direction.dart";
import "../domain/avatar_motion_state.dart";
import "../domain/avatar_scene.dart";
import "../domain/avatar_view_model.dart";
import "../domain/avatar_position.dart";
import "../presentation/avatar_animation_controller.dart";
import "avatar_catalog_loader.dart";

class AvatarSceneLoader {
  static Future<AvatarScene> load({
    required String characterId,
    required String displayName,
  }) async {
    final catalog = await _loadCatalog();
    final character = catalog.characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => catalog.defaultCharacter,
    );

    final frameImages = await loadFrameImages(character);

    return AvatarScene(
      catalog: catalog,
      frameImages: frameImages,
      avatarController: AvatarAnimationController(
        character: character,
        direction: AvatarDirection.front,
        motionState: AvatarMotionState.idle,
      ),
      avatar: AvatarViewModel(
        characterId: character.id,
        displayName: displayName,
        position: const AvatarPosition(x: 0, y: 0),
        direction: AvatarDirection.front,
        motionState: AvatarMotionState.idle,
        presenceLabel: "Disponível",
      ),
    );
  }

  static Future<AvatarScene> loadDefault() =>
      load(characterId: "character-01", displayName: "Você");

  static Future<Map<String, ui.Image>> loadFrameImages(
    AvatarCharacter character,
  ) async {
    final paths = [
      character.frames.idleFront,
      character.frames.idleBack,
      character.frames.idleLeft,
      character.frames.idleRight,
      ...character.frames.walkDown,
      ...character.frames.walkLeft,
      ...character.frames.walkRight,
      ...character.frames.walkUp,
    ];

    final entries = await Future.wait(
      paths.map((path) async {
        try {
          final fullPath = "assets/sprites/characters/$path";
          final bytes = await rootBundle.load(fullPath);
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          return MapEntry(path, frame.image);
        } catch (_) {
          return null;
        }
      }),
    );

    return Map.fromEntries(
      entries.whereType<MapEntry<String, ui.Image>>(),
    );
  }

  static Future<AvatarCatalog> _loadCatalog() async {
    try {
      return await AvatarCatalogLoader.loadDefault();
    } catch (_) {
      return const AvatarCatalog(
        version: 1,
        spriteWidth: 32,
        spriteHeight: 48,
        characters: [
          AvatarCharacter(
            id: "character-01",
            displayName: "Brown Hair Blue Suit",
            defaultCharacter: true,
            frames: AvatarCharacterFrames(
              idleFront: "character-01/idle-front.png",
              idleBack: "character-01/idle-back.png",
              idleLeft: "character-01/idle-left.png",
              idleRight: "character-01/idle-right.png",
              walkDown: ["character-01/walk-down-01.png", "character-01/walk-down-02.png"],
              walkLeft: ["character-01/walk-left-01.png", "character-01/walk-left-02.png"],
              walkRight: ["character-01/walk-right-01.png", "character-01/walk-right-02.png"],
              walkUp: ["character-01/walk-up-01.png", "character-01/walk-up-02.png"],
            ),
            hitbox: AvatarHitbox(x: 6, y: 22, width: 20, height: 24),
          ),
        ],
      );
    }
  }
}
