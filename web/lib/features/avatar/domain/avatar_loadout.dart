/// Seleção de camadas do avatar customizado (paper-doll).
///
/// Serializa para um id compacto ("custom:body=x;hair=y;top=z") que trafega
/// pelo mesmo canal do characterId dos presets. Consumidores que não conhecem
/// o formato caem no personagem default via `catalog.defaultCharacter`.
class AvatarLoadout {
  const AvatarLoadout({
    required this.bodyId,
    this.hairId,
    this.topId,
    this.bottomId,
    this.shoesId,
    this.beardId,
    this.hairColor,
    this.topColor,
    this.bottomColor,
  });

  final String bodyId;
  final String? hairId;
  final String? topId;
  final String? bottomId;
  final String? shoesId;
  final String? beardId;

  /// Cores em hex RRGGBB (sem #). null = paleta original do sprite.
  final String? hairColor;
  final String? topColor;
  final String? bottomColor;

  static const _prefix = "custom:";

  /// itemId por slot do catálogo modular; null quando o slot está vazio.
  String? itemFor(String slotId) => switch (slotId) {
        "body" => bodyId,
        "hair" => hairId,
        "top" => topId,
        "bottom" => bottomId,
        "shoes" => shoesId,
        "beard" => beardId,
        _ => null,
      };

  /// Cor (hex RRGGBB) aplicada ao slot; null quando é a paleta original.
  String? colorFor(String slotId) => switch (slotId) {
        "hair" => hairColor,
        "top" => topColor,
        "bottom" => bottomColor,
        _ => null,
      };

  AvatarLoadout withItem(String slotId, String? itemId) {
    return AvatarLoadout(
      bodyId: slotId == "body" ? (itemId ?? bodyId) : bodyId,
      hairId: slotId == "hair" ? itemId : hairId,
      topId: slotId == "top" ? itemId : topId,
      bottomId: slotId == "bottom" ? itemId : bottomId,
      shoesId: slotId == "shoes" ? itemId : shoesId,
      beardId: slotId == "beard" ? itemId : beardId,
      hairColor: slotId == "hair" && itemId == null ? null : hairColor,
      topColor: slotId == "top" && itemId == null ? null : topColor,
      bottomColor: slotId == "bottom" && itemId == null ? null : bottomColor,
    );
  }

  AvatarLoadout withColor(String slotId, String? hex) {
    return AvatarLoadout(
      bodyId: bodyId,
      hairId: hairId,
      topId: topId,
      bottomId: bottomId,
      shoesId: shoesId,
      beardId: beardId,
      hairColor: slotId == "hair" ? hex : hairColor,
      topColor: slotId == "top" ? hex : topColor,
      bottomColor: slotId == "bottom" ? hex : bottomColor,
    );
  }

  String encode() {
    final parts = ["body=$bodyId"];
    void add(String key, String? value) {
      if (value != null) parts.add("$key=$value");
    }

    add("hair", hairId);
    add("top", topId);
    add("bottom", bottomId);
    add("shoes", shoesId);
    add("beard", beardId);
    add("hairC", hairColor);
    add("topC", topColor);
    add("botC", bottomColor);
    return "$_prefix${parts.join(';')}";
  }

  static AvatarLoadout? decode(String value) {
    if (!value.startsWith(_prefix)) return null;
    final map = <String, String>{};
    for (final part in value.substring(_prefix.length).split(";")) {
      final eq = part.indexOf("=");
      if (eq > 0) map[part.substring(0, eq)] = part.substring(eq + 1);
    }
    final body = map["body"];
    if (body == null || body.isEmpty) return null;
    return AvatarLoadout(
      bodyId: body,
      hairId: map["hair"],
      topId: map["top"],
      bottomId: map["bottom"],
      shoesId: map["shoes"],
      beardId: map["beard"],
      hairColor: map["hairC"],
      topColor: map["topC"],
      bottomColor: map["botC"],
    );
  }
}

class ModularCatalog {
  const ModularCatalog({
    required this.spriteWidth,
    required this.spriteHeight,
    required this.frameNames,
    required this.slots,
  });

  final int spriteWidth;
  final int spriteHeight;
  final List<String> frameNames;

  /// Ordenados por zIndex: desenhar na ordem da lista compõe o avatar.
  final List<ModularSlot> slots;

  ModularSlot? slot(String id) {
    for (final s in slots) {
      if (s.id == id) return s;
    }
    return null;
  }
}

class ModularSlot {
  const ModularSlot({
    required this.id,
    required this.displayName,
    required this.required,
    required this.zIndex,
    required this.items,
  });

  final String id;
  final String displayName;
  final bool required;
  final int zIndex;
  final List<ModularItem> items;

  ModularItem? item(String? itemId) {
    if (itemId == null) return null;
    for (final i in items) {
      if (i.id == itemId) return i;
    }
    return null;
  }
}

class ModularItem {
  const ModularItem({
    required this.id,
    required this.displayName,
    required this.path,
  });

  final String id;
  final String displayName;

  /// Relativo a assets/sprites/, sem barra final.
  final String path;

  String frameAsset(String frameName) =>
      "assets/sprites/$path/$frameName.png";
}