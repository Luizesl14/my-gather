import "package:flutter/material.dart";
import "package:livekit_client/livekit_client.dart";

import "call_controller.dart";

/// Floating call UI: shows a video tile for each nearby participant plus a local
/// self-preview and mic/camera controls. Renders nothing while no one is within
/// range, so the call surfaces only when a proximity bubble forms.
class ProximityCallOverlay extends StatelessWidget {
  const ProximityCallOverlay({required this.controller, super.key});

  final CallController controller;

  static const double _tileW = 160;
  static const double _tileH = 120;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final List<RemoteParticipant> nearby =
            controller.connected ? controller.nearby : const [];
        // Always return a Positioned child so the parent Stack is never sized
        // by this overlay (a non-positioned empty box would collapse it).
        if (nearby.isEmpty) {
          return const Positioned(
            left: 0,
            top: 0,
            width: 0,
            height: 0,
            child: SizedBox.shrink(),
          );
        }

        // Gather/Meet-style call bar at the TOP: video tiles in a row with the
        // mic/camera controls underneath.
        return Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final p in nearby) ...[
                        _Tile(
                          track: controller.videoTrackFor(p),
                          label: p.name.isNotEmpty ? p.name : p.identity,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _Tile(
                        track: controller.localVideoTrack,
                        label: "Você",
                        muted: !controller.micEnabled,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _Controls(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.track, required this.label, this.muted = false});

  final VideoTrack? track;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = track;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: ProximityCallOverlay._tileW,
        height: ProximityCallOverlay._tileH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (t != null)
              VideoTrackRenderer(t, fit: VideoViewFit.cover)
            else
              Container(
                color: const Color(0xFF26303F),
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF4A5A70),
                  child: Text(
                    label.isNotEmpty ? label.characters.first.toUpperCase() : "?",
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            Positioned(
              left: 6,
              bottom: 6,
              right: 6,
              child: Row(
                children: [
                  if (muted)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.mic_off, size: 14, color: Colors.redAccent),
                    ),
                  Flexible(
                    child: Text(
                      label,
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
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller});

  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD1A1E2B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundButton(
            icon: controller.micEnabled ? Icons.mic : Icons.mic_off,
            active: controller.micEnabled,
            onTap: controller.toggleMic,
            tooltip: controller.micEnabled ? "Mutar microfone" : "Ativar microfone",
          ),
          const SizedBox(width: 8),
          _RoundButton(
            icon: controller.camEnabled ? Icons.videocam : Icons.videocam_off,
            active: controller.camEnabled,
            onTap: controller.toggleCam,
            tooltip: controller.camEnabled ? "Desligar câmera" : "Ligar câmera",
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF37475A) : const Color(0xFFB23A3A),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
