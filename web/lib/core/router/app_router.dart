import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../features/auth/presentation/auth_provider.dart";

import "../../features/auth/presentation/accept_invitation_page.dart";
import "../../features/auth/presentation/login_page.dart";
import "../../features/auth/presentation/register_page.dart";
import "../../features/avatar/presentation/avatar_customizer_page.dart";
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
  // "/character" abre o customizador (fluxo padrão); os presets ficam em
  // "/character/presets" como opção secundária.
  static const characterSelection = "characterSelection";
  static const characterPresets = "characterPresets";
  static const office = "office";
  static const mapEditor = "mapEditor";
}

final appRouter = GoRouter(
  initialLocation: "/login",
  redirect: (context, state) {
    final authed = ProviderScope.containerOf(context)
        .read(authProvider)
        .isAuthenticated;
    final loc = state.matchedLocation;
    final isPublic = loc == "/login" ||
        loc == "/register" ||
        loc.startsWith("/accept-invitation");
    // F5 numa rota protegida sem sessão restaurada → login (evita office
    // renderizando deslogado com avatar/mapa default).
    if (!authed && !isPublic) return "/login";
    if (authed && loc == "/login") return "/organizations";
    return null;
  },
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
      builder: (context, state) => RegisterPage(
        invitationToken: state.uri.queryParameters['token'],
      ),
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
      builder: (context, state) => const AvatarCustomizerPage(),
    ),
    GoRoute(
      name: AppRouteNames.characterPresets,
      path: "/character/presets",
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
