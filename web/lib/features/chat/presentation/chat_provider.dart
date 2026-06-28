import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

enum ChatEntryKind { message, notice }

class ChatEntry {
  ChatEntry({
    required this.kind,
    required this.fromUserId,
    required this.fromName,
    required this.text,
    required this.at,
  });

  final ChatEntryKind kind;
  final String fromUserId;
  final String fromName;
  final String text;
  final DateTime at;
}

// Proximity bubble membership (userIds within range of the local player).
// Updated by the office page; read by the realtime layer to scope chat to
// nearby people only (Gather-style).
final nearbyUserIdsProvider = StateProvider<Set<String>>((ref) => const {});

// Last reaction received from a peer — the office page watches this to play a
// sound and show the gesture over the remote avatar.
class PeerReaction {
  PeerReaction({required this.fromUserId, required this.sprite, required this.at});
  final String fromUserId;
  final String sprite;
  final DateTime at;
}

final peerReactionProvider = StateProvider<PeerReaction?>((ref) => null);

class ChatNotifier extends Notifier<List<ChatEntry>> {
  static const _max = 200;

  @override
  List<ChatEntry> build() => const [];

  void addMessage(String fromUserId, String fromName, String text) {
    _append(ChatEntry(
      kind: ChatEntryKind.message,
      fromUserId: fromUserId,
      fromName: fromName,
      text: text,
      at: DateTime.now(),
    ));
  }

  void addNotice(String text, {String fromUserId = "", String fromName = ""}) {
    _append(ChatEntry(
      kind: ChatEntryKind.notice,
      fromUserId: fromUserId,
      fromName: fromName,
      text: text,
      at: DateTime.now(),
    ));
  }

  void clear() => state = const [];

  void _append(ChatEntry e) {
    final next = [...state, e];
    state = next.length > _max ? next.sublist(next.length - _max) : next;
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, List<ChatEntry>>(ChatNotifier.new);

// Set of userIds currently typing nearby. Each entry auto-expires after a few
// seconds in case the "stopped typing" signal is missed.
class TypingNotifier extends Notifier<Set<String>> {
  final _timers = <String, Timer>{};

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
    });
    return const {};
  }

  void setTyping(String userId, bool typing) {
    _timers[userId]?.cancel();
    if (typing) {
      state = {...state, userId};
      _timers[userId] = Timer(const Duration(seconds: 4), () {
        _timers.remove(userId);
        state = {...state}..remove(userId);
      });
    } else {
      _timers.remove(userId);
      if (state.contains(userId)) state = {...state}..remove(userId);
    }
  }

  void clear() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    state = const {};
  }
}

final typingUsersProvider =
    NotifierProvider<TypingNotifier, Set<String>>(TypingNotifier.new);
