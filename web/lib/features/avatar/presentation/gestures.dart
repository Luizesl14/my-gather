// Gather-style hand gestures shared by the dock and the on-avatar hover menu.
class Gesture {
  const Gesture(this.sprite, this.label, this.sfx);
  final String sprite;
  final String label;
  final String sfx;
}

const kGestures = <Gesture>[
  Gesture("sprites/gestures/wave.png", "Acenar", "gesture_wave"),
  Gesture("sprites/gestures/bye.png", "Tchau", "gesture_bye"),
  Gesture("sprites/gestures/point.png", "Apontar", "gesture_point"),
  Gesture("sprites/gestures/like.png", "Joinha", "gesture_like"),
];

// Default gesture (Z shortcut / dock button face).
const kWaveSprite = "sprites/gestures/wave.png";
