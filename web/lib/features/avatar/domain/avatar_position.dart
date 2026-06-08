class AvatarPosition {
  const AvatarPosition({required this.x, required this.y});

  final double x;
  final double y;

  // Round to nearest tile for collision — lets the character get within
  // 0.5 tiles of any wall/desk instead of stopping 1 full tile away.
  int get tileX => x.round();
  int get tileY => y.round();

  AvatarPosition moveBy(double dx, double dy) =>
      AvatarPosition(x: x + dx, y: y + dy);
}
