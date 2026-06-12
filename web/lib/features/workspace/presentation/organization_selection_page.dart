import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_spacing.dart";
import "../../auth/presentation/auth_provider.dart";
import "../data/workspace_service.dart";
import "workspace_provider.dart";

class OrganizationSelectionPage extends ConsumerStatefulWidget {
  const OrganizationSelectionPage({super.key});

  @override
  ConsumerState<OrganizationSelectionPage> createState() =>
      _OrganizationSelectionPageState();
}

class _OrganizationSelectionPageState
    extends ConsumerState<OrganizationSelectionPage> {
  _SetupState _state = _SetupState.loading;
  List<Organization> _orgs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final token = ref.read(authProvider).token ?? "";
    final user = ref.read(authProvider).user;
    final service = WorkspaceService(token);

    try {
      final orgs = await service.listOrganizations();
      if (!mounted) return;

      if (orgs.isEmpty) {
        final orgName = "${user?.displayName ?? "Meu"} Team";
        final result = await service.createOrganization(orgName);
        if (!mounted) return;
        ref.read(orgIdProvider.notifier).state = result.organization.id;
        ref.read(orgRoleProvider.notifier).state = "owner";
        ref.read(workspaceIdProvider.notifier).state = result.workspace.id;
        context.goNamed(AppRouteNames.characterSelection);
        return;
      }

      ref.read(orgIdProvider.notifier).state = orgs.first.id;
      ref.read(orgRoleProvider.notifier).state = orgs.first.role;

      // Busca workspace da primeira org
      final workspaces = await service.listWorkspaces(orgs.first.id);
      if (!mounted) return;

      if (workspaces.isNotEmpty) {
        ref.read(workspaceIdProvider.notifier).state = workspaces.first.id;
      }

      if (orgs.length == 1) {
        context.goNamed(AppRouteNames.characterSelection);
        return;
      }

      setState(() {
        _orgs = orgs;
        _state = _SetupState.selectOrg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Erro ao carregar. Tente novamente.";
        _state = _SetupState.error;
      });
    }
  }

  Future<void> _selectOrg(Organization org) async {
    final token = ref.read(authProvider).token ?? "";
    final service = WorkspaceService(token);
    ref.read(orgIdProvider.notifier).state = org.id;
    ref.read(orgRoleProvider.notifier).state = org.role;
    try {
      final workspaces = await service.listWorkspaces(org.id);
      if (!mounted) return;
      if (workspaces.isNotEmpty) {
        ref.read(workspaceIdProvider.notifier).state = workspaces.first.id;
      }
    } catch (_) {}
    if (mounted) context.goNamed(AppRouteNames.characterSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.app,
      body: switch (_state) {
        _SetupState.loading => _LoadingSetup(colors: colors),
        _SetupState.error => _ErrorState(
            colors: colors,
            message: _error ?? "",
            onRetry: () {
              setState(() => _state = _SetupState.loading);
              _setup();
            },
          ),
        _SetupState.selectOrg => _OrgList(
            colors: colors,
            orgs: _orgs,
            onSelect: _selectOrg,
          ),
      },
    );
  }
}

enum _SetupState { loading, error, selectOrg }

class _LoadingSetup extends StatelessWidget {
  const _LoadingSetup({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: colors.brandPrimary),
          ),
          const SizedBox(height: 20),
          Text(
            "Preparando seu espaço...",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.colors, required this.message, required this.onRetry});
  final AppColors colors;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: colors.red),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text("Tentar novamente")),
        ],
      ),
    );
  }
}

class _OrgList extends StatelessWidget {
  const _OrgList({required this.colors, required this.orgs, required this.onSelect});
  final AppColors colors;
  final List<Organization> orgs;
  final ValueChanged<Organization> onSelect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Selecione a organização",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              ...orgs.map(
                (org) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    onTap: () => onSelect(org),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: colors.panel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.brandPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              org.name[0].toUpperCase(),
                              style: TextStyle(
                                color: colors.brandPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Text(
                              org.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
                        ],
                      ),
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
