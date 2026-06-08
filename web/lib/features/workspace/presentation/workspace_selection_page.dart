import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_spacing.dart";
import "../../auth/presentation/auth_provider.dart";
import "../data/workspace_service.dart" show Workspace, WorkspaceService, extractApiError;
import "workspace_provider.dart";

final _workspacesProvider =
    FutureProvider.autoDispose.family<List<Workspace>, String>(
  (ref, orgId) async {
    final token = ref.watch(authProvider).token ?? "";
    return WorkspaceService(token).listWorkspaces(orgId);
  },
);

class WorkspaceSelectionPage extends ConsumerStatefulWidget {
  const WorkspaceSelectionPage({super.key});

  @override
  ConsumerState<WorkspaceSelectionPage> createState() =>
      _WorkspaceSelectionPageState();
}

class _WorkspaceSelectionPageState
    extends ConsumerState<WorkspaceSelectionPage> {
  bool _isCreating = false;
  String? _deletingId;

  Future<void> _showCreateDialog(String orgId) async {
    final controller = TextEditingController();
    final colors = context.appColors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.panel,
        title: Text(
          "Novo escritório",
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Nome do escritório",
            hintStyle: TextStyle(color: colors.textMuted),
          ),
          style: TextStyle(color: colors.textPrimary),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Cancelar", style: TextStyle(color: colors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Criar"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final token = ref.read(authProvider).token ?? "";
      await WorkspaceService(token).createWorkspace(orgId, name);
      if (mounted) ref.invalidate(_workspacesProvider(orgId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao criar: ${extractApiError(e)}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _confirmDelete(Workspace ws, String orgId) async {
    final colors = context.appColors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.panel,
        title: Text(
          "Excluir escritório",
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Tem certeza que deseja excluir \"${ws.name}\"?\nEsta ação não pode ser desfeita.",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Cancelar", style: TextStyle(color: colors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = ws.id);
    try {
      final token = ref.read(authProvider).token ?? "";
      await WorkspaceService(token).deleteWorkspace(ws.id);
      if (mounted) ref.invalidate(_workspacesProvider(orgId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao excluir: ${extractApiError(e)}")),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final orgId = ref.watch(orgIdProvider);
    final workspacesAsync = ref.watch(_workspacesProvider(orgId));

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          context.goNamed(AppRouteNames.organizationSelection),
                      icon: Icon(Icons.arrow_back, color: colors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Escritórios",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            "Selecione ou crie um escritório",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Criar novo
                    _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FilledButton.icon(
                            onPressed: orgId.isEmpty
                                ? null
                                : () => _showCreateDialog(orgId),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Novo"),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 24),

                // Lista
                workspacesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _EmptyState(
                    colors: colors,
                    onTap: orgId.isEmpty
                        ? null
                        : () => _showCreateDialog(orgId),
                  ),
                  data: (workspaces) => workspaces.isEmpty
                      ? _EmptyState(
                          colors: colors,
                          onTap: orgId.isEmpty
                              ? null
                              : () => _showCreateDialog(orgId),
                        )
                      : Column(
                          children: workspaces.map((ws) {
                            return _WorkspaceCard(
                              workspace: ws,
                              colors: colors,
                              isDeleting: _deletingId == ws.id,
                              onEnter: () => context.goNamed(
                                AppRouteNames.office,
                                pathParameters: {"workspaceId": ws.id},
                              ),
                              onEdit: () => context.goNamed(
                                AppRouteNames.mapEditor,
                                pathParameters: {"workspaceId": ws.id},
                              ),
                              onDelete: () => _confirmDelete(ws, orgId),
                            );
                          }).toList(),
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

// ─── Cards ───────────────────────────────────────────────────────────────────

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.workspace,
    required this.colors,
    required this.isDeleting,
    required this.onEnter,
    required this.onEdit,
    required this.onDelete,
  });

  final Workspace workspace;
  final AppColors colors;
  final bool isDeleting;
  final VoidCallback onEnter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            // Main row
            InkWell(
              onTap: onEnter,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.brandSecondary, colors.brandPrimary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.map_outlined,
                          color: colors.textInverse, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workspace.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            "Escritório virtual",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Entrar",
                        style: TextStyle(
                          color: colors.brandPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action bar
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: "Editar mapa",
                    color: colors.textSecondary,
                    onTap: onEdit,
                  ),
                  Container(width: 1, height: 36, color: colors.border),
                  _ActionButton(
                    icon: isDeleting
                        ? Icons.hourglass_empty
                        : Icons.delete_outline,
                    label: isDeleting ? "Excluindo..." : "Excluir",
                    color: colors.red,
                    onTap: isDeleting ? null : onDelete,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors, required this.onTap});
  final AppColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.map_outlined, size: 40, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            "Nenhum escritório ainda",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            "Crie seu primeiro escritório virtual",
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Criar escritório"),
          ),
        ],
      ),
    );
  }
}
