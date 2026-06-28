import "dart:js_interop";
import "dart:math";

import "package:web/web.dart" as web;

import "../domain/avatar_character.dart";
import "../domain/character_voice.dart";

class ReactionAudioService {
  static final _rng = Random();
  static final _cache = <String, web.HTMLAudioElement>{};

  static web.HTMLAudioElement _getOrCreate(String assetPath) {
    return _cache.putIfAbsent(assetPath, () {
      final el = web.HTMLAudioElement();
      el.src = "assets/$assetPath";
      el.preload = "auto";
      return el;
    });
  }

  static void playCatchphrase(AvatarCharacter character) {
    final audio = character.voice?.catchphrase;
    if (audio != null) _play(audio);
  }

  static void playReaction(AvatarCharacter character, {String type = "random"}) {
    final voice = character.voice;
    if (voice == null) return;
    final clip = switch (type) {
      "roar"   => voice.audioFor("roar"),
      "scream" => voice.audioFor("scream"),
      _        => _pickRandom(voice),
    };
    if (clip != null) _play(clip);
  }

  static void playScream(String gender) {
    _play("audio/voice/common/$gender/scream-ahhh-01.mp3");
  }

  static void playSfx(String sfxKey) {
    const sfxMap = {
      "footstep":     "audio/sfx/footstep-step.mp3",
      "gunshot":      "audio/sfx/gunshot-01.mp3",
      "horror_sting": "audio/sfx/horror-sting-01.mp3",
      "notify":       "audio/sfx/notify-01.mp3",
      "attention":    "audio/sfx/attention-01.mp3",
      "zoom":         "audio/sfx/zoom-01.mp3",
      "wave":          "audio/others/notify-double-chime-01.mp3",
      "chat":          "audio/others/notify-crystal-01.mp3",
      "gesture_wave":  "audio/others/notify-double-chime-01.mp3",
      "gesture_bye":   "audio/others/notify-bell-plun-01.mp3",
      "gesture_point": "audio/others/notify-crystal-01.mp3",
      "gesture_like":  "audio/others/notify-playful-01.mp3",
    };
    final path = sfxMap[sfxKey];
    if (path != null) _play(path);
  }

  static String? _pickRandom(CharacterVoice voice) {
    final pool = voice.reactionPool;
    if (pool.isEmpty) return null;
    return pool[_rng.nextInt(pool.length)];
  }

  static void _play(String assetPath) {
    try {
      final el = _getOrCreate(assetPath);
      el.currentTime = 0;
      el.play().toDart.ignore();
    } catch (_) {}
  }

  static void preloadForCharacter(AvatarCharacter character) {
    final voice = character.voice;
    if (voice == null) return;
    for (final clip in voice.reactionPool) {
      _getOrCreate(clip);
    }
    if (voice.scream != null) _getOrCreate(voice.scream!);
  }
}
