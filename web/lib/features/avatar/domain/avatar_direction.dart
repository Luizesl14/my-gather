enum AvatarDirection {
  front,
  back,
  left,
  right,
}

AvatarDirection avatarDirectionFromString(String value) {
  return switch (value) {
    "front" => AvatarDirection.front,
    "back" => AvatarDirection.back,
    "left" => AvatarDirection.left,
    "right" => AvatarDirection.right,
    _ => AvatarDirection.front,
  };
}
