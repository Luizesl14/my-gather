class AvatarCharacter {
  const AvatarCharacter({
    required this.id,
    required this.displayName,
    required this.defaultCharacter,
    required this.frames,
    required this.hitbox,
  });

  final String id;
  final String displayName;
  final bool defaultCharacter;
  final AvatarCharacterFrames frames;
  final AvatarHitbox hitbox;
}

class AvatarCharacterFrames {
  const AvatarCharacterFrames({
    required this.idleFront,
    required this.idleBack,
    required this.idleLeft,
    required this.idleRight,
    required this.walkDown,
    required this.walkLeft,
    required this.walkRight,
    required this.walkUp,
  });

  final String idleFront;
  final String idleBack;
  final String idleLeft;
  final String idleRight;
  final List<String> walkDown;
  final List<String> walkLeft;
  final List<String> walkRight;
  final List<String> walkUp;
}

class AvatarHitbox {
  const AvatarHitbox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}
