import "dart:convert";

import "package:flutter/services.dart";

import "../domain/avatar_catalog.dart";
import "../domain/avatar_character.dart";
import "../domain/character_voice.dart";

class AvatarCatalogLoader {
  static Future<AvatarCatalog> loadDefault() async {
    final text = await rootBundle
        .loadString("assets/sprites/characters/characters.json");
    return parse(text);
  }

  static AvatarCatalog parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final version = json["version"] as int? ?? 1;

    if (version >= 2) {
      return _parseV2(json);
    }
    return _parseV1(json);
  }

  static AvatarCatalog _parseV2(Map<String, dynamic> json) {
    return AvatarCatalog(
      version: json["version"] as int,
      spriteWidth: (json["spriteSize"] as Map<String, dynamic>)["w"] as int,
      spriteHeight: (json["spriteSize"] as Map<String, dynamic>)["h"] as int,
      characters: (json["characters"] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_parseCharacterV2)
          .toList(growable: false),
    );
  }

  static AvatarCharacter _parseCharacterV2(Map<String, dynamic> entry) {
    final frames = entry["frames"] as Map<String, dynamic>;
    final hitbox = entry["hitbox"] as Map<String, dynamic>;

    final categoryStr = entry["category"] as String? ?? "man";
    final category = CharacterCategory.values.firstWhere(
      (c) => c.name == categoryStr,
      orElse: () => CharacterCategory.man,
    );

    return AvatarCharacter(
      id: entry["id"] as String,
      displayName: entry["displayName"] as String,
      defaultCharacter: entry["default"] as bool? ?? false,
      type: entry["type"] as String? ?? "normal",
      category: category,
      reactions: (entry["reactions"] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
      voice: entry["voice"] != null
          ? CharacterVoice.fromJson(entry["voice"] as Map<String, dynamic>)
          : null,
      frames: AvatarCharacterFrames(
        idleFront: frames["idleFront"] as String,
        idleBack: frames["idleBack"] as String,
        idleLeft: frames["idleLeft"] as String,
        idleRight: frames["idleRight"] as String,
        walkDown: (frames["walkDown"] as List<dynamic>).cast<String>(),
        walkLeft: (frames["walkLeft"] as List<dynamic>).cast<String>(),
        walkRight: (frames["walkRight"] as List<dynamic>).cast<String>(),
        walkUp: (frames["walkUp"] as List<dynamic>).cast<String>(),
      ),
      hitbox: AvatarHitbox(
        x: hitbox["x"] as int,
        y: hitbox["y"] as int,
        width: hitbox["w"] as int,
        height: hitbox["h"] as int,
      ),
    );
  }

  static AvatarCatalog _parseV1(Map<String, dynamic> json) {
    return AvatarCatalog(
      version: json["version"] as int,
      spriteWidth: (json["spriteSize"] as Map<String, dynamic>)["w"] as int,
      spriteHeight: (json["spriteSize"] as Map<String, dynamic>)["h"] as int,
      characters: (json["characters"] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((entry) {
        final frames = entry["frames"] as Map<String, dynamic>;
        final hitbox = entry["hitbox"] as Map<String, dynamic>;
        return AvatarCharacter(
          id: entry["id"] as String,
          displayName: entry["displayName"] as String,
          defaultCharacter: entry["default"] as bool,
          frames: AvatarCharacterFrames(
            idleFront: frames["idleFront"] as String,
            idleBack: frames["idleBack"] as String,
            idleLeft: frames["idleLeft"] as String,
            idleRight: frames["idleRight"] as String,
            walkDown: (frames["walkDown"] as List<dynamic>).cast<String>(),
            walkLeft: (frames["walkLeft"] as List<dynamic>).cast<String>(),
            walkRight: (frames["walkRight"] as List<dynamic>).cast<String>(),
            walkUp: (frames["walkUp"] as List<dynamic>).cast<String>(),
          ),
          hitbox: AvatarHitbox(
            x: hitbox["x"] as int,
            y: hitbox["y"] as int,
            width: hitbox["w"] as int,
            height: hitbox["h"] as int,
          ),
        );
      }).toList(growable: false),
    );
  }
}
