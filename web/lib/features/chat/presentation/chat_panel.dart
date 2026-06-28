import "dart:async";
import "dart:js_interop";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:web/web.dart" as web;

import "../../../core/realtime/realtime_provider.dart";
import "../../../core/theme/app_colors.dart";
import "../../auth/presentation/auth_provider.dart";
import "../../avatar/presentation/character_provider.dart";
import "../../workspace/presentation/remote_avatar_provider.dart";
import "../data/voice_service.dart";
import "chat_provider.dart";

// Voice message files are served by the backend at this origin.
const voiceBaseUrl = "http://localhost:3000";

/// Gather-style side chat: shows messages and gesture/attention notices from
/// people currently within the proximity bubble, with a text input.
class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _typingTimer;
  bool _typingSent = false;
  VoiceRecorder? _voice;
  bool _recording = false;
  bool _hasText = false;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _voice?.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    final rec = _voice ??=
        VoiceRecorder(ref.read(authProvider).token ?? "");
    if (_recording) {
      setState(() => _recording = false);
      final result = await rec.stopAndUpload();
      if (result == null || !mounted) return;
      final user = ref.read(authProvider).user;
      ref.read(realtimeSessionProvider.notifier)
          .sendVoice(result.url, result.durationMs);
      ref.read(chatProvider.notifier).addVoice(
            user?.id ?? "me",
            user?.displayName ?? "Você",
            result.url,
            result.durationMs,
          );
      _scrollToEnd();
    } else {
      final ok = await rec.start();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permita o microfone para gravar.")),
          );
        }
        return;
      }
      setState(() => _recording = true);
    }
  }

  Future<void> _cancelRecord() async {
    await _voice?.cancel();
    if (mounted) setState(() => _recording = false);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _onTextChanged(String value) {
    final has = value.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    if (!_typingSent) {
      ref.read(realtimeSessionProvider.notifier).sendTyping(true);
      _typingSent = true;
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (_typingSent) {
      ref.read(realtimeSessionProvider.notifier).sendTyping(false);
      _typingSent = false;
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _stopTyping();
    final user = ref.read(authProvider).user;
    ref.read(realtimeSessionProvider.notifier).sendChat(text);
    // Echo locally — the server only relays to other people.
    ref.read(chatProvider.notifier).addMessage(
          user?.id ?? "me",
          user?.displayName ?? "Você",
          text,
        );
    _controller.clear();
    setState(() => _hasText = false);
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nearby = ref.watch(nearbyUserIdsProvider);
    // Always return a Positioned child so this never collapses the parent Stack
    // (a bare non-positioned SizedBox would shrink the whole Stack to zero).
    if (nearby.isEmpty) {
      return const Positioned(
        left: 0,
        top: 0,
        width: 0,
        height: 0,
        child: SizedBox.shrink(),
      );
    }

    final entries = ref.watch(chatProvider);
    final myId = ref.watch(authProvider).user?.id;

    return Positioned(
      right: 16,
      top: 88,
      bottom: 160,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: colors.panel.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    "Conversa (${nearby.length + 1})",
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        "Diga olá 👋",
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(10),
                      itemCount: entries.length,
                      itemBuilder: (_, i) =>
                          _EntryView(entry: entries[i], myId: myId, colors: colors),
                    ),
            ),
            _TypingIndicator(colors: colors),
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _recording
                  ? Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: colors.red),
                          tooltip: "Cancelar",
                          onPressed: _cancelRecord,
                        ),
                        const _RecordingPulse(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Gravando áudio...",
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, size: 18, color: colors.brandPrimary),
                          tooltip: "Enviar áudio",
                          onPressed: _toggleRecord,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: _onTextChanged,
                            onSubmitted: (_) => _send(),
                            style: TextStyle(color: colors.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "Mensagem...",
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _hasText
                            ? IconButton(
                                icon: const Icon(Icons.send, size: 18),
                                color: colors.brandPrimary,
                                onPressed: _send,
                              )
                            : IconButton(
                                icon: const Icon(Icons.mic, size: 20),
                                color: colors.brandPrimary,
                                tooltip: "Gravar áudio",
                                onPressed: _toggleRecord,
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small pulsing red dot shown while recording.
class _RecordingPulse extends StatefulWidget {
  const _RecordingPulse();

  @override
  State<_RecordingPulse> createState() => _RecordingPulseState();
}

class _RecordingPulseState extends State<_RecordingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFE53935),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _EntryView extends ConsumerWidget {
  const _EntryView({required this.entry, required this.myId, required this.colors});

  final ChatEntry entry;
  final String? myId;
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entry.kind == ChatEntryKind.notice) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            entry.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    final mine = entry.fromUserId == myId;
    final characterId = mine
        ? ref.watch(characterProvider)
        : (ref.watch(remoteAvatarsProvider)[entry.fromUserId]?.characterId ??
            "character-01");

    final bubble = Flexible(
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                entry.fromName,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: mine ? colors.brandPrimary : colors.panelMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: entry.kind == ChatEntryKind.voice
                ? _VoicePlayer(
                    url: voiceBaseUrl + (entry.audioUrl ?? ""),
                    durationMs: entry.durationMs ?? 0,
                    mine: mine,
                    colors: colors,
                  )
                : Text(
                    entry.text,
                    style: TextStyle(
                      color: mine ? colors.textInverse : colors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
          ),
        ],
      ),
    );

    final avatar = _CharacterAvatar(characterId: characterId, colors: colors);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: mine
            ? [bubble, const SizedBox(width: 6), avatar]
            : [avatar, const SizedBox(width: 6), bubble],
      ),
    );
  }
}

// Small circular character photo used next to chat messages.
class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({required this.characterId, required this.colors});

  final String characterId;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: colors.canvas,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        "assets/sprites/characters/$characterId/preview.png",
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.person, size: 15, color: colors.textMuted),
      ),
    );
  }
}

// Shows the character photo of whoever is typing nearby, with animated dots.
class _TypingIndicator extends ConsumerWidget {
  const _TypingIndicator({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typers = ref.watch(typingUsersProvider);
    if (typers.isEmpty) return const SizedBox.shrink();
    final remotes = ref.watch(remoteAvatarsProvider);
    final first = typers.firstWhere(
      (id) => remotes.containsKey(id),
      orElse: () => "",
    );
    if (first.isEmpty) return const SizedBox.shrink();
    final avatar = remotes[first]!;
    final extra = typers.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.canvas,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              "assets/sprites/characters/${avatar.characterId}/preview.png",
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.person, size: 14, color: colors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.panelMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const _TypingDots(),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              extra > 0
                  ? "${avatar.displayName} e +$extra digitando"
                  : "${avatar.displayName} está digitando",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// Three dots that fade in sequence (WhatsApp/Gather-style typing animation).
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.textSecondary;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value - i * 0.2) % 1.0;
            final t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
              child: Opacity(
                opacity: 0.3 + 0.7 * t.clamp(0.0, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// Play/pause a voice message via an HTML audio element (web).
class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({
    required this.url,
    required this.durationMs,
    required this.mine,
    required this.colors,
  });

  final String url;
  final int durationMs;
  final bool mine;
  final AppColors colors;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  web.HTMLAudioElement? _audio;
  bool _playing = false;

  void _toggle() {
    var a = _audio;
    if (a == null) {
      a = web.HTMLAudioElement()..src = widget.url;
      a.addEventListener(
        "ended",
        ((web.Event _) {
          if (mounted) setState(() => _playing = false);
        }).toJS,
      );
      _audio = a;
    }
    if (_playing) {
      a.pause();
      setState(() => _playing = false);
    } else {
      a.currentTime = 0;
      a.play();
      setState(() => _playing = true);
    }
  }

  @override
  void dispose() {
    _audio?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.mine ? widget.colors.textInverse : widget.colors.textPrimary;
    final secs = (widget.durationMs / 1000).ceil();
    final label = "${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}";
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _toggle,
          customBorder: const CircleBorder(),
          child: Icon(
            _playing ? Icons.pause_circle : Icons.play_circle,
            color: fg,
            size: 28,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.graphic_eq, size: 16, color: fg.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: fg, fontSize: 12)),
      ],
    );
  }
}
