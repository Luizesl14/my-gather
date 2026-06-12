import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../../../core/theme/app_colors.dart";
import "../../workspace/presentation/game/map_renderer.dart";
import "../../workspace/presentation/game/office_map.dart";
import "../domain/avatar_view_model.dart";
import "avatar_animation_controller.dart";

class AvatarRenderer extends CustomPainter {
  const AvatarRenderer({
    required this.map,
    required this.colors,
    required this.frameImages,
    required this.avatarController,
    required this.avatar,
    this.presenceDotColor,
    this.statusEmoji,
  });

  final OfficeMap map;
  final AppColors colors;
  final Map<String, ui.Image> frameImages;
  final AvatarAnimationController avatarController;
  final AvatarViewModel avatar;
  // Presence dot color resolved from the status catalog; falls back to available.
  final Color? presenceDotColor;
  final String? statusEmoji;

  @override
  void paint(Canvas canvas, Size size) {
    const zoom = MapRenderer.kDisplayZoom;
    // Position uses full tile zoom so the avatar snaps to tile grid correctly.
    // Sprite rendered at natural pixel size (no zoom) — 32×48 on screen vs
    // 64px tiles, giving the character a proportional top-down scale.
    const spriteZoom = zoom * 0.5;
    final ts = map.tileSize * zoom;
    final offset = MapRenderer.cameraOffset(size, map, avatar.position.x, avatar.position.y);
    final spawnX = avatar.position.x * ts + offset.dx;
    final spawnY = avatar.position.y * ts + offset.dy;
    final currentFrame = frameImages[avatarController.currentFramePath()];
    final spriteWidth = (currentFrame?.width.toDouble() ?? map.tileSize.toDouble()) * spriteZoom;
    final spriteHeight = (currentFrame?.height.toDouble() ?? map.tileSize.toDouble()) * spriteZoom;
    final spriteRect = Rect.fromLTWH(
      spawnX - spriteWidth / 2 + ts / 2,
      spawnY - spriteHeight + ts,
      spriteWidth,
      spriteHeight,
    );

    if (currentFrame != null) {
      final paint = Paint()..filterQuality = FilterQuality.none;
      canvas.drawImageRect(
        currentFrame,
        Rect.fromLTWH(
          0,
          0,
          currentFrame.width.toDouble(),
          currentFrame.height.toDouble(),
        ),
        spriteRect,
        paint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(spriteRect, Radius.circular(ts * 0.16)),
        Paint()..color = colors.brandPrimary,
      );
    }

    final bubbleText = statusEmoji != null
        ? "$statusEmoji ${avatar.displayName}"
        : avatar.displayName;
    final label = TextPainter(
      text: TextSpan(
        text: bubbleText,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: "…",
    )..layout(maxWidth: 140);

    // Layout: [10px pad][dot Ø7][6px gap][name][10px pad]
    const dotRadius = 3.5;
    final bubbleWidth = label.width + 10 + dotRadius * 2 + 6 + 10;
    final bubbleHeight = label.height + 10;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          spriteRect.center.dx,
          spriteRect.top - bubbleHeight / 2 - 4,
        ),
        width: bubbleWidth,
        height: bubbleHeight,
      ),
      Radius.circular(bubbleHeight / 2),
    );

    canvas.drawRRect(
      bubbleRect,
      Paint()..color = colors.panel.withValues(alpha: 0.96),
    );
    canvas.drawRRect(
      bubbleRect,
      Paint()
        ..color = colors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final statusDot = Paint()
      ..color = presenceDotColor ?? colors.presenceAvailable;
    canvas.drawCircle(
      Offset(bubbleRect.left + 10 + dotRadius, bubbleRect.center.dy),
      dotRadius,
      statusDot,
    );

    label.paint(
      canvas,
      Offset(
        bubbleRect.left + 10 + dotRadius * 2 + 6,
        bubbleRect.top + 5,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant AvatarRenderer oldDelegate) {
    return oldDelegate.frameImages != frameImages ||
        oldDelegate.avatar.displayName != avatar.displayName ||
        oldDelegate.avatar.position.x != avatar.position.x ||
        oldDelegate.avatar.position.y != avatar.position.y ||
        oldDelegate.avatarController.direction != avatarController.direction ||
        oldDelegate.avatarController.motionState !=
            avatarController.motionState ||
        oldDelegate.map != map ||
        oldDelegate.colors != colors ||
        oldDelegate.presenceDotColor != presenceDotColor ||
        oldDelegate.statusEmoji != statusEmoji;
  }

}
