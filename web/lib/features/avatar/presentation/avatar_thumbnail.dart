import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../../../core/theme/app_colors.dart";
import "../data/modular_avatar_baker.dart";
import "../domain/avatar_loadout.dart";

/// Miniatura de personagem que funciona para presets e customizados.
///
/// Presets usam o preview.png pré-renderizado. Ids "custom:" não têm arquivo
/// de preview, então a miniatura usa o idle-front assado pelo
/// [ModularAvatarBaker] — mesmas camadas e cores do jogo, em miniatura.
class AvatarThumbnail extends StatelessWidget {
  const AvatarThumbnail({
    super.key,
    required this.characterId,
    this.fit = BoxFit.cover,
  });

  final String characterId;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final loadout = AvatarLoadout.decode(characterId);
    if (loadout == null) {
      return Image.asset(
        "assets/sprites/characters/$characterId/preview.png",
        fit: fit,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _fallbackIcon(context),
      );
    }

    return FutureBuilder<ui.Image>(
      future: ModularAvatarBaker.bakeFrame(loadout, "idle-front"),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) return _fallbackIcon(context);
        return RawImage(
          image: image,
          fit: fit,
          filterQuality: FilterQuality.none,
        );
      },
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Icon(
        Icons.person,
        size: constraints.biggest.shortestSide * 0.55,
        color: context.appColors.textMuted,
      ),
    );
  }
}