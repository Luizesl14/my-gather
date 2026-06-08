import "package:flutter/widgets.dart";

abstract final class AppRadius {
  static const double button = 6;
  static const double panel = 8;
  static const double modal = 8;

  static const BorderRadius buttonBorder =
      BorderRadius.all(Radius.circular(button));
  static const BorderRadius panelBorder =
      BorderRadius.all(Radius.circular(panel));
  static const BorderRadius modalBorder =
      BorderRadius.all(Radius.circular(modal));
}
