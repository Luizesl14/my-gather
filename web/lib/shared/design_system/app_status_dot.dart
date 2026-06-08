import "package:flutter/material.dart";

import "../../core/theme/app_colors.dart";

enum AppPresenceStatus {
  available,
  away,
  busy,
  meeting,
  focus,
  offline,
}

class AppStatusDot extends StatelessWidget {
  const AppStatusDot({
    required this.status,
    super.key,
    this.size = 10,
  });

  final AppPresenceStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final color = switch (status) {
      AppPresenceStatus.available => colors.presenceAvailable,
      AppPresenceStatus.away => colors.presenceAway,
      AppPresenceStatus.busy => colors.presenceBusy,
      AppPresenceStatus.meeting => colors.presenceMeeting,
      AppPresenceStatus.focus => colors.presenceFocus,
      AppPresenceStatus.offline => colors.presenceOffline,
    };

    return Semantics(
      label: "status ${status.name}",
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: colors.panel, width: 2),
        ),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}
