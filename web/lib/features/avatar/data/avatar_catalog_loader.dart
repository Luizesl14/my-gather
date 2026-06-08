import "dart:convert";

import "package:flutter/services.dart";

import "../domain/avatar_catalog.dart";
import "../domain/avatar_character.dart";

class AvatarCatalogLoader {
  static Future<AvatarCatalog> loadDefault() async {
    final text = await rootBundle
        .loadString("assets/sprites/characters/characters.json");
    return parse(text);
  }

  static AvatarCatalog parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;

    return AvatarCatalog(
      version: json["version"] as int,
      spriteWidth: (json["spriteSize"] as Map<String, dynamic>)["w"] as int,
      spriteHeight: (json["spriteSize"] as Map<String, dynamic>)["h"] as int,
      characters: (json["characters"] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (entry) => AvatarCharacter(
              id: entry["id"] as String,
              displayName: entry["displayName"] as String,
              defaultCharacter: entry["default"] as bool,
              frames: AvatarCharacterFrames(
                idleFront: (entry["frames"]
                    as Map<String, dynamic>)["idleFront"] as String,
                idleBack: (entry["frames"] as Map<String, dynamic>)["idleBack"]
                    as String,
                idleLeft: (entry["frames"] as Map<String, dynamic>)["idleLeft"]
                    as String,
                idleRight: (entry["frames"]
                    as Map<String, dynamic>)["idleRight"] as String,
                walkDown: ((entry["frames"] as Map<String, dynamic>)["walkDown"]
                        as List<dynamic>)
                    .cast<String>(),
                walkLeft: ((entry["frames"] as Map<String, dynamic>)["walkLeft"]
                        as List<dynamic>)
                    .cast<String>(),
                walkRight: ((entry["frames"]
                        as Map<String, dynamic>)["walkRight"] as List<dynamic>)
                    .cast<String>(),
                walkUp: ((entry["frames"] as Map<String, dynamic>)["walkUp"]
                        as List<dynamic>)
                    .cast<String>(),
              ),
              hitbox: AvatarHitbox(
                x: (entry["hitbox"] as Map<String, dynamic>)["x"] as int,
                y: (entry["hitbox"] as Map<String, dynamic>)["y"] as int,
                width: (entry["hitbox"] as Map<String, dynamic>)["w"] as int,
                height: (entry["hitbox"] as Map<String, dynamic>)["h"] as int,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
