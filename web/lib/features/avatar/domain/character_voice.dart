class CharacterVoice {
  const CharacterVoice({
    required this.voiceGender,
    this.catchphrase,
    this.roar,
    this.pool,
    this.scream,
  });

  final String voiceGender;
  final String? catchphrase;
  final String? roar;
  final String? pool;
  final String? scream;

  factory CharacterVoice.fromJson(Map<String, dynamic> json) => CharacterVoice(
        voiceGender: json["voiceGender"] as String? ?? "male",
        catchphrase: json["catchphrase"] as String?,
        roar: json["roar"] as String?,
        pool: json["pool"] as String?,
        scream: json["scream"] as String?,
      );

  // Audio clips available for random reaction playback
  List<String> get reactionPool {
    final clips = <String>[];
    if (catchphrase != null) clips.add(catchphrase!);
    if (pool != null) {
      // generic gendered pool
      for (final expr in ["oh-my-god-01", "oops-01", "please-01", "shit-01"]) {
        clips.add("$pool/$expr.mp3");
      }
    }
    return clips;
  }

  // Returns audio for a specific reaction type
  String? audioFor(String reactionType) {
    return switch (reactionType) {
      "roar"       => roar ?? catchphrase,
      "scream"     => scream,
      "catchphrase"=> catchphrase,
      _            => catchphrase ?? (pool != null ? "$pool/oops-01.mp3" : null),
    };
  }
}
