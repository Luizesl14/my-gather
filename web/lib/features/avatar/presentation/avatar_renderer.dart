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
    this.subtitle,
  });

  final OfficeMap map;
  final AppColors colors;
  final Map<String, ui.Image> frameImages;
  final AvatarAnimationController avatarController;
  final AvatarViewModel avatar;
  // Presence dot color resolved from the status catalog; falls back to available.
  final Color? presenceDotColor;
  final String? statusEmoji;
  // Segunda linha da etiqueta ("função | equipe"); omitida quando vazia.
  final String? subtitle;

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = map.displayZoom;
    final ts = map.tileSize * zoom;
    final offset = MapRenderer.cameraOffset(size, map, avatar.position.x, avatar.position.y, zoom: zoom);
    final spawnX = avatar.position.x * ts + offset.dx;
    final spawnY = avatar.position.y * ts + offset.dy;
    final currentFrame = frameImages[avatarController.currentFramePath()];
    final double targetH = ts * map.avatarScale;
    final double srcW = currentFrame?.width.toDouble() ?? ts;
    final double srcH = currentFrame?.height.toDouble() ?? (ts * 1.5);
    final spriteWidth = srcW * (targetH / srcH);
    final spriteHeight = targetH;
    final spriteRect = Rect.fromLTWH(
      spawnX - spriteWidth / 2 + ts / 2 + ts * map.avatarXOffset,
      spawnY - spriteHeight + ts - ts * map.avatarYOffset,
      spriteWidth,
      spriteHeight,
    );

    if (currentFrame != null) {
      // Pixel art: interpolação borra os sprites; nearest mantém o pixel duro.
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
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: "…",
    )..layout(maxWidth: 150);

    // Segunda linha opcional: "função | equipe", menor e discreta.
    final sub = (subtitle != null && subtitle!.trim().isNotEmpty)
        ? (TextPainter(
            text: TextSpan(
              text: subtitle,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: "…",
          )..layout(maxWidth: 150))
        : null;

    // Layout: [10px pad][dot Ø7][6px gap][texto][10px pad]
    const dotRadius = 3.5;
    final textWidth =
        sub == null ? label.width : (label.width > sub.width ? label.width : sub.width);
    final bubbleWidth = textWidth + 10 + dotRadius * 2 + 6 + 10;
    final bubbleHeight = label.height + (sub?.height ?? 0) + 10;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          spriteRect.center.dx,
          spriteRect.top - bubbleHeight / 2 - 4,
        ),
        width: bubbleWidth,
        height: bubbleHeight,
      ),
      Radius.circular(sub == null ? bubbleHeight / 2 : 10),
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
      Offset(bubbleRect.left + 10 + dotRadius, bubbleRect.top + 5 + label.height / 2),
      dotRadius,
      statusDot,
    );

    final textLeft = bubbleRect.left + 10 + dotRadius * 2 + 6;
    label.paint(canvas, Offset(textLeft, bubbleRect.top + 5));
    sub?.paint(canvas, Offset(textLeft, bubbleRect.top + 5 + label.height));
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
        oldDelegate.statusEmoji != statusEmoji ||
        oldDelegate.subtitle != subtitle;
  }

}
