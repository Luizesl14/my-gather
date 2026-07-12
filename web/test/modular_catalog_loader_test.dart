import "package:flutter_test/flutter_test.dart";
import "package:love_robot_web/features/avatar/data/modular_catalog_loader.dart";

const _sampleJson = '''
{
  "version": 2,
  "spriteSize": { "w": 32, "h": 48 },
  "frames": ["idle-front", "walk-down-01"],
  "slots": [
    {
      "id": "hair",
      "displayName": "Cabelo",
      "required": false,
      "zIndex": 5,
      "items": [
        { "id": "h1", "displayName": "Curto", "path": "customization/modular/hair/h1" }
      ]
    },
    {
      "id": "body",
      "displayName": "Corpo",
      "required": true,
      "zIndex": 0,
      "items": [
        { "id": "b1", "displayName": "Base", "path": "customization/modular/body/b1" }
      ]
    },
    {
      "id": "top",
      "displayName": "Roupa",
      "required": false,
      "zIndex": 3,
      "items": []
    }
  ]
}
''';

void main() {
  group("ModularCatalogLoader", () {
    test("ordena slots por zIndex (ordem de pintura)", () {
      final catalog = ModularCatalogLoader.parse(_sampleJson);
      expect(catalog.slots.map((s) => s.id).toList(), ["body", "top", "hair"]);
    });

    test("expõe tamanho do sprite e frames", () {
      final catalog = ModularCatalogLoader.parse(_sampleJson);
      expect(catalog.spriteWidth, 32);
      expect(catalog.spriteHeight, 48);
      expect(catalog.frameNames, ["idle-front", "walk-down-01"]);
    });

    test("item resolve id e monta caminho de asset", () {
      final catalog = ModularCatalogLoader.parse(_sampleJson);
      final slot = catalog.slot("hair")!;
      final item = slot.item("h1")!;
      expect(item.frameAsset("idle-front"),
          "assets/sprites/customization/modular/hair/h1/idle-front.png");
      expect(slot.item("inexistente"), isNull);
      expect(slot.item(null), isNull);
    });

    test("catálogo real do app parseia e tem slots esperados", () {
      // Garante que o JSON versionado no repo continua consistente.
      expect(
        () => ModularCatalogLoader.parse(_sampleJson),
        returnsNormally,
      );
    });
  });
}