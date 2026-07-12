import "package:flutter_test/flutter_test.dart";
import "package:love_robot_web/features/avatar/domain/avatar_loadout.dart";

void main() {
  group("AvatarLoadout encode/decode", () {
    test("roundtrip completo com todas as peças e cores", () {
      const loadout = AvatarLoadout(
        bodyId: "anime-unissex",
        hairId: "anime-hair-02",
        topId: "hoodie-orange",
        bottomId: "jeans",
        shoesId: "sneakers",
        beardId: "beard-01",
        hairColor: "D9A441",
        topColor: "B03A3A",
        bottomColor: "2E2E2E",
      );

      final decoded = AvatarLoadout.decode(loadout.encode());

      expect(decoded, isNotNull);
      expect(decoded!.bodyId, "anime-unissex");
      expect(decoded.hairId, "anime-hair-02");
      expect(decoded.topId, "hoodie-orange");
      expect(decoded.bottomId, "jeans");
      expect(decoded.shoesId, "sneakers");
      expect(decoded.beardId, "beard-01");
      expect(decoded.hairColor, "D9A441");
      expect(decoded.topColor, "B03A3A");
      expect(decoded.bottomColor, "2E2E2E");
    });

    test("roundtrip mínimo: só corpo", () {
      const loadout = AvatarLoadout(bodyId: "anime-unissex");
      final decoded = AvatarLoadout.decode(loadout.encode());
      expect(decoded, isNotNull);
      expect(decoded!.bodyId, "anime-unissex");
      expect(decoded.hairId, isNull);
      expect(decoded.topId, isNull);
      expect(decoded.hairColor, isNull);
    });

    test("ids de preset não são loadouts", () {
      expect(AvatarLoadout.decode("character-01"), isNull);
      expect(AvatarLoadout.decode(""), isNull);
    });

    test("custom sem body é inválido", () {
      expect(AvatarLoadout.decode("custom:hair=x"), isNull);
      expect(AvatarLoadout.decode("custom:body="), isNull);
    });

    test("decode ignora chaves desconhecidas (compatível com versões futuras)",
        () {
      final decoded =
          AvatarLoadout.decode("custom:body=b;hair=h;futuro=xyz;hairC=112233");
      expect(decoded, isNotNull);
      expect(decoded!.bodyId, "b");
      expect(decoded.hairId, "h");
      expect(decoded.hairColor, "112233");
    });

    test("withItem limpa a cor ao remover a peça do slot", () {
      const loadout = AvatarLoadout(
        bodyId: "b",
        hairId: "h",
        hairColor: "112233",
      );
      final removed = loadout.withItem("hair", null);
      expect(removed.hairId, isNull);
      expect(removed.hairColor, isNull);

      final swapped = loadout.withItem("hair", "h2");
      expect(swapped.hairId, "h2");
      expect(swapped.hairColor, "112233",
          reason: "trocar de peça mantém a cor escolhida");
    });

    test("withColor afeta só o slot alvo", () {
      const loadout = AvatarLoadout(bodyId: "b", hairId: "h", topId: "t");
      final colored = loadout.withColor("top", "AABBCC");
      expect(colored.topColor, "AABBCC");
      expect(colored.hairColor, isNull);
      expect(colored.hairId, "h");
    });

    test("itemFor/colorFor mapeiam todos os slots", () {
      const loadout = AvatarLoadout(
        bodyId: "b",
        hairId: "h",
        topId: "t",
        bottomId: "bt",
        shoesId: "s",
        beardId: "bd",
        hairColor: "111111",
        topColor: "222222",
        bottomColor: "333333",
      );
      expect(loadout.itemFor("body"), "b");
      expect(loadout.itemFor("hair"), "h");
      expect(loadout.itemFor("top"), "t");
      expect(loadout.itemFor("bottom"), "bt");
      expect(loadout.itemFor("shoes"), "s");
      expect(loadout.itemFor("beard"), "bd");
      expect(loadout.itemFor("desconhecido"), isNull);
      expect(loadout.colorFor("hair"), "111111");
      expect(loadout.colorFor("top"), "222222");
      expect(loadout.colorFor("bottom"), "333333");
      expect(loadout.colorFor("shoes"), isNull);
    });
  });
}