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
  bool _screenSharing = false;
  bool _deafened = false;
  bool _micBeforeDeafen = true;
  Set<String> _inRange = const {};

  bool get connected => _connected;
  // Reflect the ACTUAL local track state so a server-side (admin) mute also
  // turns the dock/control icons off — not just our own toggle.
  bool get micEnabled =>
      _room?.localParticipant?.isMicrophoneEnabled() ?? _micEnabled;
  bool get camEnabled =>
      _room?.localParticipant?.isCameraEnabled() ?? _camEnabled;
  bool get screenSharing => _screenSharing;

  /// Deafen estilo Discord: você não ouve ninguém e fica mudo. Implementado
  /// dessinscrevendo apenas os tracks de ÁUDIO dos vizinhos (vídeo continua).
  bool get deafened => _deafened;

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
      ..on<TrackMutedEvent>((_) => notifyListeners())
      ..on<TrackUnmutedEvent>((_) => notifyListeners())
      ..on<ActiveSpeakersChangedEvent>((_) => notifyListeners())
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
      final inRange = _inRange.contains(p.identity);
      for (final pub in p.trackPublications.values) {
        final isAudio = pub.kind == TrackType.AUDIO;
        final want = inRange && !(_deafened && isAudio);
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

  VideoTrack? get localVideoTrack => _cameraTrackOf(_room?.localParticipant);
  VideoTrack? videoTrackFor(RemoteParticipant p) => _cameraTrackOf(p);

  VideoTrack? get localScreenTrack => _screenTrackOf(_room?.localParticipant);
  VideoTrack? screenTrackFor(RemoteParticipant p) => _screenTrackOf(p);

  // The first active screen-share track among local + nearby (for the big tile).
  VideoTrack? get activeScreenTrack {
    final local = _screenTrackOf(_room?.localParticipant);
    if (local != null) return local;
    for (final p in nearby) {
      final t = _screenTrackOf(p);
      if (t != null) return t;
    }
    return null;
  }

  VideoTrack? _cameraTrackOf(Participant? p) {
    if (p == null) return null;
    for (final pub in p.videoTrackPublications) {
      if (pub.source == TrackSource.screenShareVideo) continue;
      if (pub.muted) continue; // camera off → show avatar, not a frozen frame
      final track = pub.track;
      if (track is VideoTrack) return track;
    }
    return null;
  }

  // True when the remote's microphone is muted (for the tile indicator).
  bool isMicMuted(Participant p) => p.isMuted;

  // Active-speaker detection (for the speaking outline).
  bool isSpeaking(Participant p) => p.isSpeaking;
  bool get localSpeaking => _room?.localParticipant?.isSpeaking ?? false;

  VideoTrack? _screenTrackOf(Participant? p) {
    if (p == null) return null;
    for (final pub in p.videoTrackPublications) {
      if (pub.source != TrackSource.screenShareVideo) continue;
      final track = pub.track;
      if (track is VideoTrack) return track;
    }
    return null;
  }

  Future<void> toggleMic() async {
    // Como no Discord: reativar o mic enquanto ensurdecido desfaz o deafen.
    if (_deafened) {
      await toggleDeafen();
      if (!micEnabled) {
        _micEnabled = true;
        await _room?.localParticipant?.setMicrophoneEnabled(true);
        notifyListeners();
      }
      return;
    }
    _micEnabled = !micEnabled;
    await _room?.localParticipant?.setMicrophoneEnabled(_micEnabled);
    notifyListeners();
  }

  Future<void> toggleDeafen() async {
    _deafened = !_deafened;
    if (_deafened) {
      // Deafen implica mudo; guarda o estado do mic para restaurar depois.
      _micBeforeDeafen = micEnabled;
      _micEnabled = false;
      await _room?.localParticipant?.setMicrophoneEnabled(false);
    } else {
      _micEnabled = _micBeforeDeafen;
      await _room?.localParticipant?.setMicrophoneEnabled(_micEnabled);
    }
    _applySubscriptions();
    notifyListeners();
  }

  Future<void> toggleCam() async {
    _camEnabled = !camEnabled;
    await _room?.localParticipant?.setCameraEnabled(_camEnabled);
    notifyListeners();
  }

  Future<void> toggleScreenShare() async {
    final next = !_screenSharing;
    try {
      await _room?.localParticipant?.setScreenShareEnabled(next);
      _screenSharing = next;
    } catch (e) {
      // User cancelled the screen picker, or it's unsupported.
      _screenSharing = false;
      debugPrint("[CALL] screen share failed: $e");
    }
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
