import "dart:ui" as ui;

import "../presentation/avatar_animation_controller.dart";
import "avatar_catalog.dart";
import "avatar_view_model.dart";

class AvatarScene {
  const AvatarScene({
    required this.catalog,
    required this.frameImages,
    required this.avatarController,
    required this.avatar,
  });

  final AvatarCatalog catalog;
  final Map<String, ui.Image> frameImages;
  final AvatarAnimationController avatarController;
  final AvatarViewModel avatar;
}
