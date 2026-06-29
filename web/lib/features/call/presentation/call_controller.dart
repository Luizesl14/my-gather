import "package:flutter/foundation.dart";
import "package:livekit_client/livekit_client.dart";

/// Wraps a LiveKit [Room] and turns it into a Gather-style proximity call:
/// everyone in the workspace joins the same SFU room, but each client only
/// subscribes to peers within range (set via [setInRange]). Walking away
/// unsubscribes automatically, so the "call" forms and dissolves by distance.
class CallController extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _connected = false;
  bool _micEnabled = true;
  bool _camEnabled = true;
  Set<String> _inRange = const {};

  bool get connected => _connected;
  bool get micEnabled => _micEnabled;
  bool get camEnabled => _camEnabled;

  Future<void> connect(String url, String token) async {
    if (_room != null) return;
    final room = Room();
    _room = room;

    final listener = room.createListener();
    _listener = listener;
    listener
      ..on<TrackPublishedEvent>((_) => _applySubscriptions())
      ..on<TrackSubscribedEvent>((_) => notifyListeners())
      ..on<TrackUnsubscribedEvent>((_) => notifyListeners())
      ..on<ParticipantConnectedEvent>((_) {
        _applySubscriptions();
        notifyListeners();
      })
      ..on<ParticipantDisconnectedEvent>((_) => notifyListeners())
      ..on<RoomDisconnectedEvent>((_) {
        _connected = false;
        notifyListeners();
      });

    await room.connect(
      url,
      token,
      connectOptions: const ConnectOptions(autoSubscribe: false),
    );
    // Connected to the room — surface the call UI even if mic/cam fail.
    _connected = true;
    _applySubscriptions();
    notifyListeners();
    debugPrint("[CALL] connected. remotes=${room.remoteParticipants.length}");

    // Best-effort media: a missing camera or denied permission must not break
    // the call (you can still see/hear others).
    try {
      await room.localParticipant?.setMicrophoneEnabled(_micEnabled);
    } catch (e) {
      _micEnabled = false;
      debugPrint("[CALL] mic failed: $e");
    }
    try {
      await room.localParticipant?.setCameraEnabled(_camEnabled);
    } catch (e) {
      _camEnabled = false;
      debugPrint("[CALL] cam failed: $e");
    }
    notifyListeners();
  }

  // Identities (userIds) currently within proximity range.
  void setInRange(Set<String> identities) {
    if (setEquals(_inRange, identities)) return;
    _inRange = identities;
    _applySubscriptions();
    notifyListeners();
  }

  void _applySubscriptions() {
    final room = _room;
    if (room == null) return;
    for (final p in room.remoteParticipants.values) {
      final want = _inRange.contains(p.identity);
      for (final pub in p.trackPublications.values) {
        if (want && !pub.subscribed) {
          pub.subscribe();
        } else if (!want && pub.subscribed) {
          pub.unsubscribe();
        }
      }
    }
  }

  List<RemoteParticipant> get nearby {
    final room = _room;
    if (room == null) return const [];
    return room.remoteParticipants.values
        .where((p) => _inRange.contains(p.identity))
        .toList(growable: false);
  }

  VideoTrack? get localVideoTrack => _videoTrackOf(_room?.localParticipant);

  VideoTrack? videoTrackFor(RemoteParticipant p) => _videoTrackOf(p);

  VideoTrack? _videoTrackOf(Participant? p) {
    if (p == null) return null;
    for (final pub in p.videoTrackPublications) {
      final track = pub.track;
      if (track is VideoTrack) return track;
    }
    return null;
  }

  Future<void> toggleMic() async {
    _micEnabled = !_micEnabled;
    await _room?.localParticipant?.setMicrophoneEnabled(_micEnabled);
    notifyListeners();
  }

  Future<void> toggleCam() async {
    _camEnabled = !_camEnabled;
    await _room?.localParticipant?.setCameraEnabled(_camEnabled);
    notifyListeners();
  }

  Future<void> shutdown() async {
    await _listener?.dispose();
    _listener = null;
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
    _connected = false;
  }

  @override
  void dispose() {
    shutdown();
    super.dispose();
  }
}
