class AvatarPosition {
  const AvatarPosition({required this.x, required this.y});

  final double x;
  final double y;

  int get tileX => x.floor();
  int get tileY => y.floor();

  AvatarPosition moveBy(double dx, double dy) =>
      AvatarPosition(x: x + dx, y: y + dy);
}
