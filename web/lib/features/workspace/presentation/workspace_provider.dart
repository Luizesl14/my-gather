import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../auth/presentation/auth_provider.dart";
import "../data/workspace_service.dart";

final workspaceIdProvider = StateProvider<String>((ref) => "office-default");
final orgIdProvider = StateProvider<String>((ref) => "");
// Current user's role in the selected org: owner | admin | member.
// Gates map-editing features (e.g., the in-game collision overlay toggle).
final orgRoleProvider = StateProvider<String>((ref) => "member");

// Members of the selected org — the "who's in the room" roster used by
// targeted reactions (e.g. wave at someone). Empty until an org is selected.
final orgMembersProvider = FutureProvider<List<OrgMember>>((ref) async {
  final orgId = ref.watch(orgIdProvider);
  final token = ref.watch(authProvider).token;
  if (orgId.isEmpty || token == null) return const [];
  return WorkspaceService(token).listMembers(orgId);
});
