import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:livekit_client/livekit_client.dart";

import "../../../core/theme/app_colors.dart";
import "../../avatar/presentation/character_provider.dart";
import "../../chat/presentation/chat_provider.dart";
import "../../workspace/presentation/remote_avatar_provider.dart";
import "call_controller.dart";

const _screenId = "__screen__";
// Docker-blue outline shown around the active speaker (Gather-style).
const _speakingColor = Color(0xFF2496ED);

// True while the call is in the big spotlight view — the office dock hides then.
final callSpotlightProvider = StateProvider<bool>((ref) => false);

class _Pvm {
  _Pvm({
    required this.id,
    required this.name,
    required this.characterId,
    required this.cam,
    required this.micMuted,
    required this.isLocal,
    required this.speaking,
  });
  final String id;
  final String name;
  final String characterId;
  final VideoTrack? cam;
  final bool micMuted;
  final bool isLocal;
  final bool speaking;
}

/// Gather/Meet-style call. Compact translucent bar at the top by default. When
/// someone shares their screen or you pin a person, switches to an adaptive
/// Meet layout: a big spotlight on the left + a filmstrip column on the right.
class ProximityCallOverlay extends ConsumerStatefulWidget {
  const ProximityCallOverlay({
    required this.controller,
    required this.onMutePeer,
    super.key,
  });

  final CallController controller;
  final void Function(String identity, bool muted) onMutePeer;

  @override
  ConsumerState<ProximityCallOverlay> createState() =>
      _ProximityCallOverlayState();
}

class _ProximityCallOverlayState extends ConsumerState<ProximityCallOverlay> {
  String? _pinned; // participant id or _screenId
  bool _lastSpotlight = false;

  void _reportSpotlight(bool spotlight) {
    if (spotlight == _lastSpotlight) return;
    _lastSpotlight = spotlight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(callSpotlightProvider.notifier).state = spotlight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final remotes = ref.watch(remoteAvatarsProvider);
    final myCharacterId = ref.watch(characterProvider);
    // Reserve room on the right for the chat drawer (Meet-style).
    final rightInset =
        ref.watch(chatOpenProvider) ? chatPanelWidth + 24 : 0.0;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final nearby = c.connected ? c.nearby : const <RemoteParticipant>[];
        if (nearby.isEmpty) {
          _reportSpotlight(false);
          return const Positioned(
            left: 0, top: 0, width: 0, height: 0,
            child: SizedBox.shrink(),
          );
        }

        final people = <_Pvm>[
          _Pvm(
            id: "__me__",
            name: "Você",
            characterId: myCharacterId,
            cam: c.localVideoTrack,
            micMuted: !c.micEnabled,
            isLocal: true,
            speaking: c.localSpeaking,
          ),
          for (final p in nearby)
            _Pvm(
              id: p.identity,
              name: p.name.isNotEmpty
                  ? p.name
                  : (remotes[p.identity]?.displayName ?? "Colega"),
              characterId: remotes[p.identity]?.characterId ?? "character-01",
              cam: c.videoTrackFor(p),
              micMuted: c.isMicMuted(p),
              isLocal: false,
              speaking: c.isSpeaking(p),
            ),
        ];

        final screen = c.activeScreenTrack;
        // Resolve which item is the big spotlight (pinned wins; else screen).
        String? bigTarget = _pinned;
        if (bigTarget != null &&
            bigTarget != _screenId &&
            !people.any((v) => v.id == bigTarget)) {
          bigTarget = null; // pinned person left
        }
        bigTarget ??= screen != null ? _screenId : null;

        _reportSpotlight(bigTarget != null);
        if (bigTarget == null) {
          return _compactBar(colors, people, rightInset);
        }
        return _spotlight(colors, people, screen, bigTarget, rightInset);
      },
    );
  }

  // ── Compact top bar ────────────────────────────────────────────────────────
  Widget _compactBar(AppColors colors, List<_Pvm> people, double rightInset) {
    return Positioned(
      top: 12,
      left: 0,
      right: rightInset,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: _panel(
            colors,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < people.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _tile(colors, people[i], const Size(132, 88)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Adaptive Meet layout: big spotlight + filmstrip column ─────────────────
  Widget _spotlight(
    AppColors colors,
    List<_Pvm> people,
    VideoTrack? screen,
    String bigTarget,
    double rightInset,
  ) {
    final Widget big;
    if (bigTarget == _screenId && screen != null) {
      big = _ScreenView(track: screen);
    } else {
      final vm = people.firstWhere((v) => v.id == bigTarget, orElse: () => people.first);
      big = _BigCam(vm: vm, colors: colors);
    }

    // Filmstrip: people + the screen (so you can pin/unpin it), excluding the
    // one currently big.
    final strip = <Widget>[
      for (final v in people)
        if (v.id != bigTarget) _tile(colors, v, const Size(180, 116)),
      if (screen != null && bigTarget != _screenId)
        _stripScreen(colors, screen),
    ];

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      right: rightInset,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(child: big),
                if (strip.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: ListView.separated(
                      itemCount: strip.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => strip[i],
                    ),
                  ),
                ],
              ],
            ),
            // Bottom control bar (mic / camera / screen / reduce).
            Align(
              alignment: Alignment.bottomCenter,
              child: _SpotlightControls(
                controller: widget.controller,
                onReduce: () => setState(() => _pinned = null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stripScreen(AppColors colors, VideoTrack screen) {
    return GestureDetector(
      onTap: () => setState(() => _pinned = _screenId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 116,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black,
                child: VideoTrackRenderer(screen, fit: VideoViewFit.contain),
              ),
              const Positioned(
                left: 6, bottom: 6,
                child: Text("Tela",
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(AppColors colors, Widget child) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.panel.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _tile(AppColors colors, _Pvm vm, Size size) => _Tile(
        key: ValueKey(vm.id),
        vm: vm,
        size: size,
        colors: colors,
        pinned: _pinned == vm.id,
        onTap: () => setState(() => _pinned = _pinned == vm.id ? null : vm.id),
        onToggleMute:
            vm.isLocal ? null : () => widget.onMutePeer(vm.id, !vm.micMuted),
      );
}

class _BigCam extends StatelessWidget {
  const _BigCam({required this.vm, required this.colors});
  final _Pvm vm;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final t = vm.cam;
    // 16:9 box so the video fills it (cover) and the outline hugs the video.
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (t != null)
                VideoTrackRenderer(t, fit: VideoViewFit.cover)
              else
                _AvatarFill(characterId: vm.characterId, big: true),
              Positioned(
                left: 12, bottom: 10,
                child: Row(
                  children: [
                    if (vm.micMuted)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.mic_off, size: 18, color: Colors.redAccent),
                      ),
                    Text(vm.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        )),
                  ],
                ),
              ),
              if (vm.speaking)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _speakingColor, width: 4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenView extends StatelessWidget {
  const _ScreenView({required this.track});
  final VideoTrack track;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoTrackRenderer(track, fit: VideoViewFit.contain),
                const Positioned(
                  left: 12, top: 10,
                  child: Row(
                    children: [
                      Icon(Icons.screen_share, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text("Tela compartilhada",
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.vm,
    required this.size,
    required this.colors,
    required this.pinned,
    required this.onTap,
    required this.onToggleMute,
    super.key,
  });

  final _Pvm vm;
  final Size size;
  final AppColors colors;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback? onToggleMute;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final t = vm.cam;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: widget.size.width,
            height: widget.size.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (t != null)
                  VideoTrackRenderer(t, fit: VideoViewFit.cover)
                else
                  _AvatarFill(characterId: vm.characterId),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Color(0x99000000), Color(0x00000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 8, bottom: 6, right: 8,
                  child: Row(
                    children: [
                      if (vm.micMuted)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.mic_off, size: 13, color: Colors.redAccent),
                        ),
                      Flexible(
                        child: Text(
                          vm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (vm.speaking)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _speakingColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                if (widget.pinned)
                  const Positioned(
                    left: 6, top: 6,
                    child: Icon(Icons.push_pin, size: 14, color: Colors.white),
                  ),
                // Hover: mute/unmute toggle (mic on by default, red when muted).
                if (_hover && widget.onToggleMute != null)
                  Positioned(
                    right: 6, top: 6,
                    child: _MiniButton(
                      icon: vm.micMuted ? Icons.mic_off : Icons.mic,
                      muted: vm.micMuted,
                      tooltip: vm.micMuted ? "Reativar microfone" : "Mutar para todos",
                      onTap: widget.onToggleMute!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarFill extends StatelessWidget {
  const _AvatarFill({required this.characterId, this.big = false});
  final String characterId;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final d = big ? 96.0 : 48.0;
    return Container(
      color: const Color(0xFF1B2230),
      alignment: Alignment.center,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: const Color(0xFF2A3445),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          "assets/sprites/characters/$characterId/preview.png",
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.person, color: Colors.white54, size: d * 0.55),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.muted,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final bool muted;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: muted ? const Color(0xE6B23A3A) : const Color(0xE6263243),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
      ),
    );
  }
}

// Meet-style control bar shown at the bottom of the spotlight view.
class _SpotlightControls extends StatelessWidget {
  const _SpotlightControls({required this.controller, required this.onReduce});

  final CallController controller;
  final VoidCallback onReduce;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final c = controller;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xCC11151F),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CtrlButton(
                icon: c.micEnabled ? Icons.mic : Icons.mic_off,
                active: c.micEnabled,
                tooltip: c.micEnabled ? "Mutar" : "Ativar microfone",
                onTap: c.toggleMic,
              ),
              const SizedBox(width: 10),
              _CtrlButton(
                icon: c.camEnabled ? Icons.videocam : Icons.videocam_off,
                active: c.camEnabled,
                tooltip: c.camEnabled ? "Desligar câmera" : "Ligar câmera",
                onTap: c.toggleCam,
              ),
              const SizedBox(width: 10),
              _CtrlButton(
                icon: c.screenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                active: !c.screenSharing,
                tooltip: c.screenSharing
                    ? "Parar compartilhamento"
                    : "Compartilhar tela",
                onTap: c.toggleScreenShare,
              ),
              const SizedBox(width: 10),
              _CtrlButton(
                icon: Icons.close_fullscreen,
                active: true,
                tooltip: "Reduzir",
                onTap: onReduce,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CtrlButton extends StatelessWidget {
  const _CtrlButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF37475A) : const Color(0xFFB23A3A),
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}
