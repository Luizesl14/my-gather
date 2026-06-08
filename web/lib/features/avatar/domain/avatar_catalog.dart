import "avatar_character.dart";

class AvatarCatalog {
  const AvatarCatalog({
    required this.version,
    required this.spriteWidth,
    required this.spriteHeight,
    required this.characters,
  });

  final int version;
  final int spriteWidth;
  final int spriteHeight;
  final List<AvatarCharacter> characters;

  AvatarCharacter get defaultCharacter =>
      characters.firstWhere((character) => character.defaultCharacter,
          orElse: () => characters.first);
}
