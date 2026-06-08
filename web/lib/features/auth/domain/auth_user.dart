class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.defaultAvatarId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json["id"] as String,
        email: json["email"] as String,
        displayName: json["displayName"] as String,
        defaultAvatarId: (json["defaultAvatarId"] as String?) ?? "character-01",
      );

  final String id;
  final String email;
  final String displayName;
  final String defaultAvatarId;
}
