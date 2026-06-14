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

  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/invitations/$token/accept",
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
