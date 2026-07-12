class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.defaultAvatarId,
    this.role = "",
    this.team = "",
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json["id"] as String,
        email: json["email"] as String,
        displayName: json["displayName"] as String,
        defaultAvatarId: (json["defaultAvatarId"] as String?) ?? "character-01",
        role: (json["role"] as String?) ?? "",
        team: (json["team"] as String?) ?? "",
      );

  final String id;
  final String email;
  final String displayName;
  final String defaultAvatarId;

  /// Função e equipe exibidas na etiqueta do avatar ("função | equipe").
  final String role;
  final String team;

  AuthUser copyWith({String? displayName, String? role, String? team}) =>
      AuthUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        defaultAvatarId: defaultAvatarId,
        role: role ?? this.role,
        team: team ?? this.team,
      );

  /// "função | equipe", omitindo partes vazias.
  String get subtitle => [role, team]
      .where((s) => s.trim().isNotEmpty)
      .join(" | ");
}
