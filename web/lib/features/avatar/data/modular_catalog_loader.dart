import "dart:convert";

import "package:flutter/services.dart";

import "../domain/avatar_loadout.dart";

class ModularCatalogLoader {
  static Future<ModularCatalog> loadDefault() async {
    final text = await rootBundle.loadString(
      "assets/sprites/customization/modular/modular-catalog.json",
    );
    return parse(text);
  }

  static ModularCatalog parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final sprite = json["spriteSize"] as Map<String, dynamic>;

    final slots = (json["slots"] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (slot) => ModularSlot(
            id: slot["id"] as String,
            displayName: slot["displayName"] as String,
            required: slot["required"] as bool? ?? false,
            zIndex: slot["zIndex"] as int? ?? 0,
            items: (slot["items"] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map(
                  (item) => ModularItem(
                    id: item["id"] as String,
                    displayName: item["displayName"] as String,
                    path: item["path"] as String,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return ModularCatalog(
      spriteWidth: sprite["w"] as int,
      spriteHeight: sprite["h"] as int,
      frameNames:
          (json["frames"] as List<dynamic>).cast<String>(),
      slots: List.unmodifiable(slots),
    );
  }
}