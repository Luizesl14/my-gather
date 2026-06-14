import "package:animated_emoji/animated_emoji.dart";
import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/realtime/realtime_provider.dart";
import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_spacing.dart";
import "../../../shared/design_system/design_system.dart";
import "../../auth/presentation/auth_provider.dart";
import "../../avatar/presentation/character_provider.dart";
import "../../avatar/presentation/presence_provider.dart";
import "../data/workspace_service.dart";
import "game/office_canvas.dart";
import "remote_avatar_provider.dart";
import "workspace_provider.dart";

// Keyboard shortcuts for the reaction hotbar (Gather-style: keys 1..5).
const _reactionKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
];

class OfficePage extends ConsumerStatefulWidget {
  const OfficePage({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  ConsumerState<OfficePage> createState() => _OfficePageState();
}

class _OfficePageState extends ConsumerState<OfficePage> {
  static const _wsUrl = "ws://localhost:3001/ws";

  @override
  void initState() {
    super.initState();
    // Defer connection until the widget tree is mounted so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  @override
  void dispose() {
    ref.read(realtimeSessionProvider.notifier).leave(widget.workspaceId);
    super.dispose();
  }

  void _connect() {
    final token = ref.read(authProvider).token;
    final characterId = ref.read(characterProvider);
    if (token == null) return;
    ref.read(realtimeSessionProvider.notifier).join(
      wsUrl: _wsUrl,
      token: token,
      workspaceId: widget.workspaceId,
      characterId: characterId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = ref.watch(authProvider).user;
    final characterId = ref.watch(characterProvider);
    final displayName = user?.displayName ?? "Você";
    final role = ref.watch(orgRoleProvider);
    final canEditMap = role == "owner" || role == "admin";
    final status = ref.watch(userStatusProvider);
    final catalog = ref.watch(statusCatalogProvider).valueOrNull;
    final dotColor = presenceColor(
        colors, catalog?.presenceById(status.presenceId)?.colorKey ?? "");
    final reactions = catalog?.reactions ?? const <ReactionOption>[];
    final remoteAvatars = ref.watch(remoteAvatarsProvider);
    final session = ref.read(realtimeSessionProvider.notifier);

    return Scaffold(
      backgroundColor: colors.app,
      body: CallbackShortcuts(
        bindings: {
          for (var i = 0; i < reactions.length && i < _reactionKeys.length; i++)
            SingleActivator(_reactionKeys[i]): () {
              // Don't steal digits while the user types a custom status.
              final focused = FocusManager.instance.primaryFocus?.context;
              if (focused?.findAncestorStateOfType<EditableTextState>() !=
                  null) {
                return;
              }
              ref
                  .read(activeReactionProvider.notifier)
                  .trigger(reactions[i].sprite);
            },
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: OfficeCanvas(
                characterId: characterId,
                displayName: displayName,
                workspaceId: widget.workspaceId,
                token: ref.watch(authProvider).token ?? "",
                canToggleCollision: canEditMap,
                presenceDotColor: dotColor,
                statusEmoji: status.emoji,
                reactionSprite: ref.watch(activeReactionProvider)?.sprite,
                reactionTargetName:
                    ref.watch(activeReactionProvider)?.targetName,
                remoteAvatars: remoteAvatars,
                onAvatarMoved: (x, y, direction, motionState) =>
                    session.sendMove(x, y, direction, motionState),
                onAvatarStopped: (x, y, direction) =>
                    session.sendStop(x, y, direction),
              ),
            ),
            Positioned(
              top: AppSpacing.xl,
              left: AppSpacing.xl,
              child: AppPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconButton(
                      icon: Icons.arrow_back,
                      tooltip: "Voltar",
                      onPressed: () =>
                          context.goNamed(AppRouteNames.characterSelection),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Escritório",
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          displayName,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: AppSpacing.lg,
              left: 0,
              right: 0,
              child: Center(child: _BottomDock()),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom dock (Gather-style toolbar) ──────────────────────────────────────
//
// Layout: [ avatar + name + status ▾ │ reaction hotbar (1..5) │ emoji status ]
// The identity section toggles the status panel; reactions fire in one click.

class _BottomDock extends ConsumerStatefulWidget {
  const _BottomDock();

  @override
  ConsumerState<_BottomDock> createState() => _BottomDockState();
}

class _BottomDockState extends ConsumerState<_BottomDock> {
  bool _statusOpen = false;
  // Reaction awaiting a target ("wave at whom?"); null = picker closed.
  ReactionOption? _pickerReaction;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _applyText() {
    ref.read(userStatusProvider.notifier).update(
        (s) => s.copyWith(customText: _textController.text.trim()));
    setState(() => _statusOpen = false);
  }

  Future<void> _pickEmoji(BuildContext context) async {
    final colors = context.appColors;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          width: 360,
          height: 440,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: EmojiPicker(
              onEmojiSelected: (_, emoji) {
                ref
                    .read(userStatusProvider.notifier)
                    .update((s) => s.copyWith(emoji: emoji.emoji));
                Navigator.of(ctx).pop();
              },
              config: const Config(
                checkPlatformCompatibility: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = ref.watch(userStatusProvider);
    final catalog = ref.watch(statusCatalogProvider).valueOrNull;
    if (catalog == null) return const SizedBox.shrink();

    final currentPresence = catalog.presenceById(status.presenceId);
    final currentColor =
        presenceColor(colors, currentPresence?.colorKey ?? "");

    final Widget overlay;
    if (_statusOpen) {
      overlay = Padding(
        key: const ValueKey("status-panel"),
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _StatusPanel(
          textController: _textController,
          onApplyText: _applyText,
          onPickEmoji: () => _pickEmoji(context),
        ),
      );
    } else if (_pickerReaction != null) {
      overlay = Padding(
        key: ValueKey("target-picker-${_pickerReaction!.id}"),
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _ReactionTargetPicker(
          reaction: _pickerReaction!,
          onDone: () => setState(() => _pickerReaction = null),
        ),
      );
    } else {
      overlay = const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status panel / reaction target picker (animated in/out above the dock)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
          child: overlay,
        ),

        // The dock itself
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.panel.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Identity: avatar + name + status, toggles the panel.
                InkWell(
                  onTap: () => setState(() {
                    _statusOpen = !_statusOpen;
                    _pickerReaction = null;
                    if (_statusOpen) {
                      _textController.text = status.customText ?? "";
                    }
                  }),
                  borderRadius: BorderRadius.circular(12),
                  hoverColor: colors.panelMuted,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AvatarBadge(
                          size: 42,
                          dotColor: currentColor,
                          characterId: ref.watch(characterProvider),
                        ),
                        const SizedBox(width: AppSpacing.md + 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.watch(authProvider).user?.displayName ??
                                    "Você",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status.emoji != null) ...[
                                    _EmojiView(
                                        emoji: status.emoji!, size: 13),
                                    const SizedBox(width: 4),
                                  ],
                                  Flexible(
                                    child: Text(
                                      status.labelWith(catalog),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AnimatedRotation(
                          turns: _statusOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.expand_less,
                            size: 16,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _DockDivider(color: colors.border),

                // Reaction hotbar. Click opens the target picker when there
                // are other people in the room; keys 1..5 send to everyone.
                for (final (i, r) in catalog.reactions.indexed)
                  _DockReaction(
                    sprite: r.sprite,
                    label: r.label,
                    shortcut: i < _reactionKeys.length ? "${i + 1}" : null,
                    active: _pickerReaction?.id == r.id,
                    onTap: () {
                      final members =
                          ref.read(orgMembersProvider).valueOrNull ??
                              const <OrgMember>[];
                      final myId = ref.read(authProvider).user?.id;
                      final others =
                          members.where((m) => m.id != myId).toList();
                      if (others.isEmpty) {
                        ref
                            .read(activeReactionProvider.notifier)
                            .trigger(r.sprite);
                        setState(() => _pickerReaction = null);
                        return;
                      }
                      setState(() {
                        _statusOpen = false;
                        _pickerReaction =
                            _pickerReaction?.id == r.id ? null : r;
                      });
                    },
                  ),

                _DockDivider(color: colors.border),

                // Status emoji shortcut.
                Tooltip(
                  message: status.emoji == null
                      ? "Emoji de status"
                      : "Trocar emoji de status",
                  child: InkWell(
                    onTap: () => _pickEmoji(context),
                    borderRadius: BorderRadius.circular(12),
                    hoverColor: colors.panelMuted,
                    child: SizedBox(
                      width: 44,
                      height: 48,
                      child: Center(
                        child: status.emoji != null
                            ? _EmojiView(emoji: status.emoji!, size: 24)
                            : Icon(
                                Icons.add_reaction_outlined,
                                size: 21,
                                color: colors.textSecondary,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DockDivider extends StatelessWidget {
  const _DockDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: color,
    );
  }
}

// Avatar preview with the presence dot, shared by the dock and the panel.
class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.size,
    required this.dotColor,
    required this.characterId,
  });

  final double size;
  final Color dotColor;
  final String characterId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.canvas,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/sprites/characters/$characterId/preview.png",
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => Icon(Icons.person,
                  size: size * 0.55, color: colors.textMuted),
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: size * 0.32,
            height: size * 0.32,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.panel, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// One slot of the reaction hotbar: sprite on top, shortcut hint below.
// Sprites are 32px pixel art — rendered at native size to stay crisp.
class _DockReaction extends StatelessWidget {
  const _DockReaction({
    required this.sprite,
    required this.label,
    required this.onTap,
    this.shortcut,
    this.active = false,
  });

  final String sprite;
  final String label;
  final String? shortcut;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: shortcut == null ? label : "$label  ·  $shortcut",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: colors.panelMuted,
        child: Container(
          width: 50,
          height: 56,
          decoration: BoxDecoration(
            color: active
                ? colors.brandPrimary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/$sprite",
                width: 32,
                height: 32,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(height: 1),
              Text(
                shortcut ?? "",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: active ? colors.brandPrimary : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// "Wave at whom?" — lists people in the room; picking one sends the gesture
// with their name attached. First row sends to everyone.
class _ReactionTargetPicker extends ConsumerWidget {
  const _ReactionTargetPicker({required this.reaction, required this.onDone});

  final ReactionOption reaction;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final myId = ref.watch(authProvider).user?.id;
    final members = ref.watch(orgMembersProvider).valueOrNull ??
        const <OrgMember>[];
    final others = members.where((m) => m.id != myId).toList();

    void send(String? targetName) {
      ref
          .read(activeReactionProvider.notifier)
          .trigger(reaction.sprite, targetName: targetName);
      onDone();
    }

    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.panel.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.xs, bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Image.asset(
                    "assets/${reaction.sprite}",
                    width: 20,
                    height: 20,
                    filterQuality: FilterQuality.none,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    "${reaction.label} — para quem?",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _TargetRow(
              leading: Icon(Icons.groups_outlined,
                  size: 18, color: colors.textSecondary),
              label: "Todos na sala",
              onTap: () => send(null),
            ),
            ...others.map((m) => _TargetRow(
                  leading: _AvatarBadge(
                    size: 24,
                    dotColor: colors.presenceAvailable,
                    characterId: m.avatarId,
                  ),
                  label: m.displayName,
                  onTap: () => send(m.displayName),
                )),
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.leading,
    required this.label,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: colors.panelMuted,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(width: 26, height: 26, child: Center(child: leading)),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status panel ─────────────────────────────────────────────────────────────

class _StatusPanel extends ConsumerWidget {
  const _StatusPanel({
    required this.textController,
    required this.onApplyText,
    required this.onPickEmoji,
  });

  final TextEditingController textController;
  final VoidCallback onApplyText;
  final VoidCallback onPickEmoji;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final status = ref.watch(userStatusProvider);
    final notifier = ref.read(userStatusProvider.notifier);
    final catalog = ref.watch(statusCatalogProvider).valueOrNull;
    if (catalog == null) return const SizedBox.shrink();

    final hasCustom = (status.customText != null &&
            status.customText!.isNotEmpty) ||
        status.emoji != null;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.panel.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel("Disponibilidade", color: colors.textMuted),
            const SizedBox(height: AppSpacing.sm),

            // Presence options (from the status catalog asset)
            ...catalog.presences.map((opt) {
              final selected = status.presenceId == opt.id;
              return InkWell(
                onTap: () =>
                    notifier.update((s) => s.copyWith(presenceId: opt.id)),
                borderRadius: BorderRadius.circular(10),
                hoverColor: colors.panelMuted,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md + 2, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.brandPrimary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: presenceColor(colors, opt.colorKey),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md + 2),
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check,
                            size: 15, color: colors.brandPrimary),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.lg),
            _SectionLabel("Status", color: colors.textMuted),
            const SizedBox(height: AppSpacing.sm),

            // Combined emoji + text input (Slack/Gather style).
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: colors.panelMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Tooltip(
                    message: "Emoji de status",
                    child: InkWell(
                      onTap: onPickEmoji,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12)),
                      hoverColor: colors.canvas,
                      child: SizedBox(
                        width: 42,
                        height: 44,
                        child: Center(
                          child: status.emoji != null
                              ? _EmojiView(emoji: status.emoji!, size: 22)
                              : Icon(
                                  Icons.sentiment_satisfied_alt_outlined,
                                  size: 19,
                                  color: colors.textMuted,
                                ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: textController,
                      onSubmitted: (_) => onApplyText(),
                      style:
                          TextStyle(fontSize: 13, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Qual é o seu status?",
                        hintStyle:
                            TextStyle(fontSize: 13, color: colors.textMuted),
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    ),
                  ),
                  if (hasCustom)
                    Tooltip(
                      message: "Limpar status",
                      child: InkWell(
                        onTap: () {
                          textController.clear();
                          notifier.update((s) =>
                              s.copyWith(clearEmoji: true, clearText: true));
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 34,
                          height: 44,
                          child: Icon(Icons.close,
                              size: 15, color: colors.textMuted),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onApplyText,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brandPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text("Salvar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

// Renders a status emoji: animated (Noto Animated Emoji) when available,
// plain text glyph otherwise. The animated version streams a Lottie over the
// network, so a neutral smiley placeholder is shown (instead of a broken
// glyph box) and cross-fades into the animation once it loads.
class _EmojiView extends StatefulWidget {
  const _EmojiView({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  State<_EmojiView> createState() => _EmojiViewState();
}

class _EmojiViewState extends State<_EmojiView> {
  bool _loaded = false;

  @override
  void didUpdateWidget(_EmojiView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emoji != widget.emoji) _loaded = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final animated = AnimatedEmojis.fromEmojiString(widget.emoji);
    if (animated == null) {
      return Text(widget.emoji,
          style: TextStyle(fontSize: widget.size * 0.8));
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!_loaded)
            Icon(
              Icons.sentiment_satisfied_alt,
              size: widget.size * 0.9,
              color: colors.textMuted.withValues(alpha: 0.4),
            ),
          AnimatedOpacity(
            opacity: _loaded ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedEmoji(
              animated,
              size: widget.size,
              onLoaded: (_) {
                if (mounted) setState(() => _loaded = true);
              },
              errorWidget: Text(widget.emoji,
                  style: TextStyle(fontSize: widget.size * 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
