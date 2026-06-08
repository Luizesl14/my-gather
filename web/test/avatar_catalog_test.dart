import "dart:io";

import "package:flutter_test/flutter_test.dart";

import "package:love_robot_web/features/avatar/data/avatar_catalog_loader.dart";

void main() {
  test("carrega o catalogo padrao de personagens", () async {
    final text =
        await File("assets/sprites/characters/characters.json").readAsString();
    final catalog = AvatarCatalogLoader.parse(text);

    expect(catalog.version, 1);
    expect(catalog.spriteWidth, 32);
    expect(catalog.spriteHeight, 48);
    expect(catalog.characters.length, 10);
    expect(catalog.defaultCharacter.id, "character-01");
    expect(catalog.defaultCharacter.frames.idleFront,
        "character-01/idle-front.png");
    expect(catalog.defaultCharacter.frames.walkDown, hasLength(2));
  });
}
