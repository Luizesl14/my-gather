import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "core/router/app_router.dart";
import "core/theme/app_theme.dart";
import "features/auth/presentation/auth_provider.dart";
import "features/avatar/domain/avatar_loadout.dart";
import "features/avatar/presentation/avatar_loadout_provider.dart";
import "features/avatar/presentation/character_provider.dart";

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  // Restaura a sessão salva ANTES de montar o router: sem isso, um F5 em
  // /office/... renderiza deslogado (avatar default, mapa default).
  late final Future<void> _bootstrap = _restore();

  Future<void> _restore() async {
    final user = await ref.read(authProvider.notifier).restoreSession();
    if (user == null) return;
    final avatar = user.defaultAvatarId;
    if (avatar.isNotEmpty) {
      ref.read(characterProvider.notifier).state = avatar;
      ref.read(avatarLoadoutProvider.notifier).state =
          AvatarLoadout.decode(avatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: "Love+Robot",
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: appRouter,
        );
      },
    );
  }
}
