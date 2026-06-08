import "package:flutter_riverpod/flutter_riverpod.dart";

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

  final AuthService _service;

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _service.login(email: email, password: password);
      state = AuthState(user: result.user, token: result.token);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.code);
      return false;
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

  void logout() => state = const AuthState();
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
