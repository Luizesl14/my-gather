import "package:dio/dio.dart";

import "../domain/auth_user.dart";

class AuthException implements Exception {
  const AuthException(this.code);
  final String code;

  @override
  String toString() => code;
}

class AuthService {
  AuthService() : _dio = Dio(BaseOptions(baseUrl: "http://localhost:3000"));

  final Dio _dio;

  Future<({AuthUser user, String token})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/auth/login",
        data: {"email": email, "password": password},
      );
      final data = response.data!;
      return (
        user: AuthUser.fromJson(data["user"] as Map<String, dynamic>),
        token: data["token"] as String,
      );
    } on DioException catch (e) {
      final code = (e.response?.data as Map?)?["error"]?["code"] as String?;
      throw AuthException(code ?? "auth.unknown_error");
    }
  }

  /// Valida um token salvo e devolve o usuário atual (GET /auth/me).
  Future<AuthUser> me(String token) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        "/auth/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return AuthUser.fromJson(
          response.data!["user"] as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = (e.response?.data as Map?)?["error"]?["code"] as String?;
      throw AuthException(code ?? "auth.unknown_error");
    }
  }

  Future<void> updateAvatar(String token, String avatarId) async {
    try {
      await _dio.put<void>(
        "/auth/me/avatar",
        data: {"avatarId": avatarId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      final code = (e.response?.data as Map?)?["error"]?["code"] as String?;
      throw AuthException(code ?? "auth.unknown_error");
    }
  }

  Future<void> updateProfile(
    String token, {
    String? displayName,
    String? role,
    String? team,
  }) async {
    try {
      await _dio.put<void>(
        "/auth/me/profile",
        data: {
          if (displayName != null) "displayName": displayName,
          if (role != null) "role": role,
          if (team != null) "team": team,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      final code = (e.response?.data as Map?)?["error"]?["code"] as String?;
      throw AuthException(code ?? "auth.unknown_error");
    }
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/auth/register",
        data: {
          "email": email,
          "password": password,
          "displayName": displayName,
        },
      );
      final data = response.data!;
      return AuthUser.fromJson(data["user"] as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = (e.response?.data as Map?)?["error"]?["code"] as String?;
      throw AuthException(code ?? "auth.unknown_error");
    }
  }

  // Reads the invitation (public) so the signup form can pre-fill the email.
  Future<({String email, bool accepted, bool expired})?> getInvitation(
    String token,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>("/invitations/$token");
      final inv = res.data!["invitation"] as Map<String, dynamic>;
      return (
        email: inv["email"] as String,
        accepted: inv["accepted"] as bool? ?? false,
        expired: inv["expired"] as bool? ?? false,
      );
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(
    String token, {
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/invitations/$token/accept",
        options: authToken != null
            ? Options(headers: {"Authorization": "Bearer $authToken"})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      final errorData = (e.response?.data as Map?);
      final code = errorData?["error"]?["code"] as String?;
      final message = errorData?["error"]?["message"] as String?;

      return {
        'success': false,
        'code': code ?? 'invitation.unknown_error',
        'message': message ?? 'Erro ao aceitar convite',
      };
    }
  }
}
