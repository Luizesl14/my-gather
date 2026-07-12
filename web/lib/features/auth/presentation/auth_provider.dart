import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:web/web.dart" as web;

import "../data/auth_service.dart";
import "../domain/auth_user.dart";

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  const AuthState({this.user, this.token, this.isLoading = false, this.error});

  final AuthUser? user;
  final String? token;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    AuthUser? user,
    String? token,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        token: clearUser ? null : (token ?? this.token),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service) : super(const AuthState());

  static const _tokenKey = "love_robot_token";

  final AuthService _service;

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _service.login(email: email, password: password);
      state = AuthState(user: result.user, token: result.token);
      // Sessão sobrevive a F5: o token fica no localStorage e o boot
      // revalida com GET /auth/me (restoreSession).
      web.window.localStorage.setItem(_tokenKey, result.token);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.code);
      return false;
    }
  }

  /// Restaura a sessão salva no localStorage; retorna o usuário ou null.
  Future<AuthUser?> restoreSession() async {
    final token = web.window.localStorage.getItem(_tokenKey);
    if (token == null || token.isEmpty) return null;
    try {
      final user = await _service.me(token);
      state = AuthState(user: user, token: token);
      return user;
    } on AuthException {
      web.window.localStorage.removeItem(_tokenKey);
      return null;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      return login(email: email, password: password);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.code);
      return false;
    }
  }

  /// Persiste nome/função/equipe e atualiza o usuário local em memória.
  Future<bool> updateProfile({
    String? displayName,
    String? role,
    String? team,
  }) async {
    final token = state.token;
    final user = state.user;
    if (token == null || user == null) return false;
    try {
      await _service.updateProfile(
        token,
        displayName: displayName,
        role: role,
        team: team,
      );
      state = state.copyWith(
        user: user.copyWith(displayName: displayName, role: role, team: team),
      );
      return true;
    } on AuthException {
      return false;
    }
  }

  void logout() {
    web.window.localStorage.removeItem(_tokenKey);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
