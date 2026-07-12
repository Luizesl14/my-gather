import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../../../core/theme/app_colors.dart";
import "../../workspace/presentation/game/map_renderer.dart";
import "../../workspace/presentation/game/office_map.dart";
import "../domain/avatar_position.dart";
import "../domain/avatar_view_model.dart";
import "avatar_animation_controller.dart";

class RemoteAvatarEntry {
  const RemoteAvatarEntry({
    required this.frameImages,
    required this.controller,
    required this.viewModel,
    this.subtitle = "",
    this.dotColor,
  });

  final Map<String, ui.Image> frameImages;
  final AvatarAnimationController controller;
  final AvatarViewModel viewModel;

  /// "função | equipe" exibido sob o nome; vazio = etiqueta de uma linha.
  final String subtitle;

  /// Cor da bolinha de presença (resolvida do catálogo); null = disponível.
  final Color? dotColor;
}

// Renders all remote avatars using the same camera math as AvatarRenderer,
// but centered on the LOCAL player's position.
class RemoteAvatarsRenderer extends CustomPainter {
  const RemoteAvatarsRenderer({
    required this.map,
    required this.colors,
    required this.localPosition,
    required this.remotes,
  });

  final OfficeMap map;
  final AppColors colors;
  final AvatarPosition localPosition;
  final List<RemoteAvatarEntry> remotes;

  @override
  void paint(Canvas canvas, Size size) {
    if (remotes.isEmpty) return;

    final zoom = map.displayZoom;
    final ts = map.tileSize * zoom;
    final offset = MapRenderer.cameraOffset(size, map, localPosition.x, localPosition.y, zoom: zoom);

    for (final remote in remotes) {
      final pos = remote.viewModel.position;
      final screenX = pos.x * ts + offset.dx;
      final screenY = pos.y * ts + offset.dy;

      final currentFrame = remote.frameImages[remote.controller.currentFramePath()];
      // Same sizing as the local AvatarRenderer: scale the sprite so its HEIGHT
      // equals avatarScale tiles, independent of the frame's pixel dimensions.
      final double targetH = ts * map.avatarScale;
      final double srcW = currentFrame?.width.toDouble() ?? ts;
      final double srcH = currentFrame?.height.toDouble() ?? (ts * 1.5);
      final sw = srcW * (targetH / srcH);
      final sh = targetH;
      final spriteRect = Rect.fromLTWH(screenX - sw / 2 + ts / 2 + ts * map.avatarXOffset, screenY - sh + ts - ts * map.avatarYOffset, sw, sh);

      if (currentFrame != null) {
        canvas.drawImageRect(
          currentFrame,
          Rect.fromLTWH(0, 0, currentFrame.width.toDouble(), currentFrame.height.toDouble()),
          spriteRect,
          Paint()..filterQuality = FilterQuality.none,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(spriteRect, Radius.circular(ts * 0.16)),
          Paint()..color = colors.brandSecondary,
        );
      }

      _drawNameBubble(canvas, remote, spriteRect);
    }
  }

  // Mesmo formato da etiqueta do avatar local: nome (14) + linha opcional
  // "função | equipe" (10) e bolinha na cor real da presença do colega.
  void _drawNameBubble(Canvas canvas, RemoteAvatarEntry remote, Rect spriteRect) {
    final label = TextPainter(
      text: TextSpan(
        text: remote.viewModel.displayName,
        style: TextStyle(
            color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: "…",
    )..layout(maxWidth: 150);

    final sub = remote.subtitle.trim().isNotEmpty
        ? (TextPainter(
            text: TextSpan(
              text: remote.subtitle,
              style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: "…",
          )..layout(maxWidth: 150))
        : null;

    const dotRadius = 3.5;
    final textWidth = sub == null
        ? label.width
        : (label.width > sub.width ? label.width : sub.width);
    final bw = textWidth + 10 + dotRadius * 2 + 6 + 10;
    final bh = label.height + (sub?.height ?? 0) + 10;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(spriteRect.center.dx, spriteRect.top - bh / 2 - 4),
        width: bw,
        height: bh,
      ),
      Radius.circular(sub == null ? bh / 2 : 10),
    );

    canvas.drawRRect(bubbleRect, Paint()..color = colors.panel.withValues(alpha: 0.96));
    canvas.drawRRect(
      bubbleRect,
      Paint()
        ..color = colors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(bubbleRect.left + 10 + dotRadius, bubbleRect.top + 5 + label.height / 2),
      dotRadius,
      Paint()..color = remote.dotColor ?? colors.presenceAvailable,
    );
    final textLeft = bubbleRect.left + 10 + dotRadius * 2 + 6;
    label.paint(canvas, Offset(textLeft, bubbleRect.top + 5));
    sub?.paint(canvas, Offset(textLeft, bubbleRect.top + 5 + label.height));
  }

  // Sempre repinta: além de posição, o balão reage a status/cor/subtítulo
  // dos remotos, que mudam por eventos — e o ticker já reconstrói a cena.
  @override
  bool shouldRepaint(covariant RemoteAvatarsRenderer old) => true;
}
