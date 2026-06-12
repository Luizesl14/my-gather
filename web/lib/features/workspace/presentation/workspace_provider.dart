import "package:flutter_riverpod/flutter_riverpod.dart";

final workspaceIdProvider = StateProvider<String>((ref) => "office-default");
final orgIdProvider = StateProvider<String>((ref) => "");
// Current user's role in the selected org: owner | admin | member.
// Gates map-editing features (e.g., the in-game collision overlay toggle).
final orgRoleProvider = StateProvider<String>((ref) => "member");
