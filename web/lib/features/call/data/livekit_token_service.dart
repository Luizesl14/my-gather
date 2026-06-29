import "package:dio/dio.dart";

class LivekitCredentials {
  const LivekitCredentials({required this.url, required this.token});
  final String url;
  final String token;
}

class LivekitTokenService {
  LivekitTokenService(String token)
      : _dio = Dio(BaseOptions(
          baseUrl: "http://localhost:3000",
          headers: {"Authorization": "Bearer $token"},
        ));

  final Dio _dio;

  /// Mutes/unmutes a participant's microphone for everyone in the room.
  Future<void> mutePeer(String workspaceId, String identity, bool muted) async {
    await _dio.post<Map<String, dynamic>>(
      "/workspaces/$workspaceId/livekit/mute",
      data: {"identity": identity, "muted": muted},
    );
  }

  /// Fetches a LiveKit access token for the workspace room. Returns null when
  /// the backend has no LiveKit configured (503) so calls degrade gracefully.
  Future<LivekitCredentials?> fetch(String workspaceId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        "/workspaces/$workspaceId/livekit-token",
      );
      final data = res.data!;
      return LivekitCredentials(
        url: data["url"] as String,
        token: data["token"] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) return null; // not configured
      rethrow;
    }
  }
}
