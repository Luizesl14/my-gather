import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../features/avatar/data/reaction_audio_service.dart";
import "../../../features/chat/presentation/chat_provider.dart";
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
    _sub = service.stream.listen(_handleEvent);

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

  void sendProfileChange(String displayName, String role, String team) {
    ref.read(realtimeServiceProvider).send({
      "type": "presence:profile.change",
      "displayName": displayName,
      "role": role,
      "team": team,
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

  void sendReaction(String sprite, {String? targetUserId}) {
    ref.read(realtimeServiceProvider).send({
      "type": "reaction",
      "sprite": sprite,
      if (targetUserId != null) "targetUserId": targetUserId,
    });
  }

  void sendChat(String text) {
    ref.read(realtimeServiceProvider).send({"type": "chat", "text": text});
  }

  void sendTyping(bool typing) {
    ref.read(realtimeServiceProvider).send({"type": "typing", "typing": typing});
  }

  void sendVoice(String url, int durationMs) {
    ref.read(realtimeServiceProvider).send({
      "type": "voice",
      "url": url,
      "durationMs": durationMs,
    });
  }

  // Routes incoming realtime events. Chat/reactions are scoped to people within
  // the proximity bubble (Gather-style); everything else updates avatars.
  void _handleEvent(Map<String, dynamic> event) {
    final type = event["type"];
    if (type == "chat" ||
        type == "reaction" ||
        type == "typing" ||
        type == "voice") {
      final fromUserId = (event["fromUserId"] as String?) ?? "";
      final nearby = ref.read(nearbyUserIdsProvider);
      if (!nearby.contains(fromUserId)) return; // ignore far-away peers
      if (type == "typing") {
        ref
            .read(typingUsersProvider.notifier)
            .setTyping(fromUserId, event["typing"] == true);
        return;
      }
      final fromName = (event["fromName"] as String?) ?? "Alguém";
      if (type == "voice") {
        ref.read(chatProvider.notifier).addVoice(
              fromUserId,
              fromName,
              (event["url"] as String?) ?? "",
              (event["durationMs"] as num?)?.toInt() ?? 0,
            );
        ReactionAudioService.playSfx("chat");
      } else if (type == "chat") {
        ref
            .read(chatProvider.notifier)
            .addMessage(fromUserId, fromName, (event["text"] as String?) ?? "");
        ReactionAudioService.playSfx("chat");
      } else {
        ref.read(chatProvider.notifier).addNotice(
              "$fromName chamou sua atenção 👋",
              fromUserId: fromUserId,
              fromName: fromName,
            );
        ref.read(peerReactionProvider.notifier).state = PeerReaction(
          fromUserId: fromUserId,
          sprite: (event["sprite"] as String?) ?? "",
          at: DateTime.now(),
        );
      }
      return;
    }
    ref.read(remoteAvatarsProvider.notifier).handleEvent(event);
  }
}

final realtimeSessionProvider =
    NotifierProvider<RealtimeSessionNotifier, bool>(RealtimeSessionNotifier.new);
