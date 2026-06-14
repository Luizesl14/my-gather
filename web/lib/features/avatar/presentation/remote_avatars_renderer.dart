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
  });

  final Map<String, ui.Image> frameImages;
  final AvatarAnimationController controller;
  final AvatarViewModel viewModel;
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

    const zoom = MapRenderer.kDisplayZoom;
    const spriteZoom = zoom * 0.5;
    final ts = map.tileSize * zoom;
    final offset = MapRenderer.cameraOffset(size, map, localPosition.x, localPosition.y);

    for (final remote in remotes) {
      final pos = remote.viewModel.position;
      final screenX = pos.x * ts + offset.dx;
      final screenY = pos.y * ts + offset.dy;

      final currentFrame = remote.frameImages[remote.controller.currentFramePath()];
      final sw = (currentFrame?.width.toDouble() ?? map.tileSize.toDouble()) * spriteZoom;
      final sh = (currentFrame?.height.toDouble() ?? map.tileSize.toDouble()) * spriteZoom;
      final spriteRect = Rect.fromLTWH(screenX - sw / 2 + ts / 2, screenY - sh + ts, sw, sh);

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

      _drawNameBubble(canvas, remote.viewModel.displayName, spriteRect);
    }
  }

  void _drawNameBubble(Canvas canvas, String name, Rect spriteRect) {
    final label = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: "…",
    )..layout(maxWidth: 140);

    const dotRadius = 3.5;
    final bw = label.width + 10 + dotRadius * 2 + 6 + 10;
    final bh = label.height + 10;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(spriteRect.center.dx, spriteRect.top - bh / 2 - 4),
        width: bw,
        height: bh,
      ),
      Radius.circular(bh / 2),
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
      Offset(bubbleRect.left + 10 + dotRadius, bubbleRect.center.dy),
      dotRadius,
      Paint()..color = colors.presenceAvailable,
    );
    label.paint(canvas, Offset(bubbleRect.left + 10 + dotRadius * 2 + 6, bubbleRect.top + 5));
  }

  @override
  bool shouldRepaint(covariant RemoteAvatarsRenderer old) =>
      old.localPosition.x != localPosition.x ||
      old.localPosition.y != localPosition.y ||
      old.remotes.length != remotes.length;
}
