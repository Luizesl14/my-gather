import "dart:async";
import "dart:ui" as ui;

import "package:flutter/painting.dart";
import "package:flutter/services.dart";

import "../domain/avatar_loadout.dart";
import "modular_catalog_loader.dart";

/// Compõe as camadas de um loadout (corpo + roupa + cabelo...) em um ui.Image
/// único por frame, no momento do load. Assim o restante do pipeline
/// (controller, renderers, remotos) segue trabalhando com "um sprite por
/// frame" e não precisa saber que o personagem é modular.
///
/// Camadas com cor escolhida passam por palette swap por luminância: o brilho
/// de cada pixel modula a cor alvo, então sombras e brilhos do sprite original
/// sobrevivem e o contorno escuro fica intocado.
///
/// Desempenho: os 16 frames são assados em paralelo e todo resultado é
/// memoizado — camadas decodificadas, versões recoloridas e o bake completo
/// por loadout. Os caches guardam Futures para que chamadas concorrentes ao
/// mesmo recurso compartilhem um único trabalho.
class ModularAvatarBaker {
  /// Prefixo das chaves de frame de personagens custom no frameImages.
  static const framePrefix = "modular://";

  static ModularCatalog? _catalogCache;
  static final Map<String, Future<ui.Image?>> _decodedLayers = {};
  static final Map<String, Future<ui.Image>> _recoloredCache = {};
  static final Map<String, Future<Map<String, ui.Image>>> _bakeCache = {};

  static Future<ModularCatalog> catalog() async =>
      _catalogCache ??= await ModularCatalogLoader.loadDefault();

  static Future<Map<String, ui.Image>> bake(AvatarLoadout loadout) {
    // Cap simples: cada bake completo ocupa ~1MB (16 frames RGBA 128x128).
    if (_bakeCache.length > 24) _bakeCache.clear();
    return _bakeCache.putIfAbsent(loadout.encode(), () => _bakeAll(loadout));
  }

  static Future<Map<String, ui.Image>> _bakeAll(AvatarLoadout loadout) async {
    final cat = await catalog();
    final entries = await Future.wait(
      cat.frameNames.map(
        (frame) async =>
            MapEntry("$framePrefix$frame", await bakeFrame(loadout, frame)),
      ),
    );
    return Map.fromEntries(entries);
  }

  /// Assa um único frame composto (usado pelo preview e pelas miniaturas).
  static Future<ui.Image> bakeFrame(
    AvatarLoadout loadout,
    String frameName,
  ) async {
    final cat = await catalog();

    // Resolve as camadas selecionadas na ordem de pintura (zIndex).
    final selected = <(ModularItem, String?)>[];
    for (final slot in cat.slots) {
      final item = slot.item(loadout.itemFor(slot.id));
      if (item != null) selected.add((item, loadout.colorFor(slot.id)));
    }

    // Decodifica (e recolore) todas as camadas em paralelo.
    final images = await Future.wait(
      selected.map((entry) async {
        final (item, hex) = entry;
        final asset = item.frameAsset(frameName);
        final image = await _layerImage(asset);
        if (image == null) return null;
        if (hex == null) return image;
        return _recolored(asset, hex, image);
      }),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final image in images) {
      if (image != null) canvas.drawImage(image, Offset.zero, paint);
    }

    return recorder
        .endRecording()
        .toImage(cat.spriteWidth, cat.spriteHeight);
  }

  static Future<ui.Image?> _layerImage(String asset) {
    return _decodedLayers.putIfAbsent(asset, () async {
      try {
        final bytes = await rootBundle.load(asset);
        final codec =
            await ui.instantiateImageCodec(bytes.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        return null;
      }
    });
  }

  static Future<ui.Image> _recolored(
    String asset,
    String hex,
    ui.Image source,
  ) {
    return _recoloredCache.putIfAbsent("$asset#$hex", () async {
      final target = _hexToRgb(hex);
      final data = await source.toByteData();
      if (data == null) return source;
      final px = data.buffer.asUint8List();

      for (var i = 0; i < px.length; i += 4) {
        if (px[i + 3] == 0) continue;
        final r = px[i], g = px[i + 1], b = px[i + 2];
        final lum = (0.30 * r + 0.59 * g + 0.11 * b);
        // Contorno e traços internos escuros ficam como estão.
        if (lum < 45) continue;
        // Luminância modula a cor alvo: 140 ≈ tom médio dos sprites, então o
        // tom médio vira exatamente a cor escolhida, sombras mais escuras e
        // brilhos mais claros.
        final f = lum / 140.0;
        px[i] = (target.$1 * f).round().clamp(0, 255);
        px[i + 1] = (target.$2 * f).round().clamp(0, 255);
        px[i + 2] = (target.$3 * f).round().clamp(0, 255);
      }

      return _imageFromPixels(px, source.width, source.height);
    });
  }

  static (int, int, int) _hexToRgb(String hex) {
    final value = int.parse(hex.replaceAll("#", ""), radix: 16);
    return ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF);
  }

  static Future<ui.Image> _imageFromPixels(Uint8List rgba, int w, int h) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      w,
      h,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}