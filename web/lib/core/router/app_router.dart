import "package:go_router/go_router.dart";

import "../../features/auth/presentation/accept_invitation_page.dart";
import "../../features/auth/presentation/login_page.dart";
import "../../features/auth/presentation/register_page.dart";
import "../../features/avatar/presentation/character_selection_page.dart";
import "../../features/workspace/presentation/map_editor/map_editor_page.dart";
import "../../features/workspace/presentation/office_page.dart";
import "../../features/workspace/presentation/organization_selection_page.dart";
import "../../features/workspace/presentation/workspace_selection_page.dart";

abstract final class AppRouteNames {
  static const login = "login";
  static const register = "register";
  static const acceptInvitation = "acceptInvitation";
  static const organizationSelection = "organizationSelection";
  static const workspaceSelection = "workspaceSelection";
  static const characterSelection = "characterSelection";
  static const office = "office";
  static const mapEditor = "mapEditor";
}

final appRouter = GoRouter(
  initialLocation: "/login",
  routes: [
    GoRoute(
      name: AppRouteNames.login,
      path: "/login",
      builder: (context, state) => LoginPage(
        extra: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      name: AppRouteNames.register,
      path: "/register",
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      name: AppRouteNames.acceptInvitation,
      path: "/accept-invitation",
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        if (token == null || token.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: const Center(
              child: Text('Token de convite inválido ou ausente'),
            ),
          );
        }
        return AcceptInvitationPage(token: token);
      },
    ),
    GoRoute(
      name: AppRouteNames.organizationSelection,
      path: "/organizations",
      builder: (context, state) => const OrganizationSelectionPage(),
    ),
    GoRoute(
      name: AppRouteNames.characterSelection,
      path: "/character",
      builder: (context, state) => const CharacterSelectionPage(),
    ),
    GoRoute(
      name: AppRouteNames.workspaceSelection,
      path: "/workspaces",
      builder: (context, state) => const WorkspaceSelectionPage(),
    ),
    GoRoute(
      name: AppRouteNames.office,
      path: "/office/:workspaceId",
      builder: (context, state) => OfficePage(
        workspaceId: state.pathParameters["workspaceId"] ?? "",
      ),
    ),
    GoRoute(
      name: AppRouteNames.mapEditor,
      path: "/workspaces/:workspaceId/editor",
      builder: (context, state) => MapEditorPage(
        workspaceId: state.pathParameters["workspaceId"] ?? "",
      ),
    ),
  ],
);
