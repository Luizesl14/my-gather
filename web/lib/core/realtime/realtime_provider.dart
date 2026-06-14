import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../features/workspace/presentation/remote_avatar_provider.dart";
import "realtime_service.dart";

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(service.dispose);
  return service;
});

// Connects to the WebSocket and pipes events to RemoteAvatarsNotifier.
// Call `ref.read(realtimeSessionProvider.notifier).join(...)` after mounting.
class RealtimeSessionNotifier extends Notifier<bool> {
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  bool build() {
    ref.onDispose(() {
      _sub?.cancel();
      ref.read(realtimeServiceProvider).disconnect();
    });
    return false;
  }

  void join({
    required String wsUrl,
    required String token,
    required String workspaceId,
    required String characterId,
  }) {
    final service = ref.read(realtimeServiceProvider);
    service.connect(wsUrl, token);

    _sub?.cancel();
    _sub = service.stream.listen((event) {
      ref.read(remoteAvatarsProvider.notifier).handleEvent(event);
    });

    service.send({
      "type": "workspace:join",
      "workspaceId": workspaceId,
      "characterId": characterId,
    });

    state = true;
  }

  void leave(String workspaceId) {
    ref.read(realtimeServiceProvider).send({"type": "workspace:leave"});
    _sub?.cancel();
    ref.read(realtimeServiceProvider).disconnect();
    ref.read(remoteAvatarsProvider.notifier).clear();
    state = false;
  }

  void sendMove(double x, double y, String direction, String motionState) {
    ref.read(realtimeServiceProvider).send({
      "type": "avatar:move",
      "x": x,
      "y": y,
      "direction": direction,
      "motionState": motionState,
    });
  }

  void sendStop(double x, double y, String direction) {
    ref.read(realtimeServiceProvider).send({
      "type": "avatar:stop",
      "x": x,
      "y": y,
      "direction": direction,
    });
  }

  void sendStatusChange(String status, {String? emoji, String? text}) {
    ref.read(realtimeServiceProvider).send({
      "type": "presence:status.change",
      "status": status,
      if (emoji != null) "emoji": emoji,
      if (text != null) "text": text,
    });
  }
}

final realtimeSessionProvider =
    NotifierProvider<RealtimeSessionNotifier, bool>(RealtimeSessionNotifier.new);
