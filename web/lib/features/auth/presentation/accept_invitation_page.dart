import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_service.dart';
import '../domain/auth_user.dart';
import 'auth_provider.dart';

class AcceptInvitationPage extends ConsumerStatefulWidget {
  final String token;

  const AcceptInvitationPage({
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<AcceptInvitationPage> createState() =>
      _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends ConsumerState<AcceptInvitationPage> {
  String? _error;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processInvitation();
    });
  }

  Future<void> _processInvitation() async {
    setState(() => _isProcessing = true);

    try {
      final authState = ref.read(authProvider);

      if (authState == null) {
        // Não está logado - redireciona para login com redirect
        if (mounted) {
          context.push(
            '/login',
            extra: {
              'redirectTo': '/accept-invitation',
              'token': widget.token,
            },
          );
        }
        return;
      }

      // Está logado - aceita o convite
      await _acceptInvitation(authState);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erro ao processar convite: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _acceptInvitation(AuthUser user) async {
    try {
      final authService = AuthService();
      final response = await authService.acceptInvitation(widget.token);

      if (!mounted) return;

      if (response['success'] == true) {
        // Sucesso - redireciona para workspace
        final organizationId = response['organizationId'] as String?;
        final workspaceId = response['workspaceId'] as String?;

        if (organizationId != null && workspaceId != null) {
          context.go('/workspaces/$workspaceId');
        } else {
          context.go('/organizations');
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Erro ao aceitar convite';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erro: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aceitando Convite'),
        centerTitle: true,
      ),
      body: Center(
        child: _error != null
            ? _ErrorWidget(error: _error!, onRetry: _processInvitation)
            : _LoadingWidget(isProcessing: _isProcessing),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  final bool isProcessing;

  const _LoadingWidget({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            isProcessing ? 'Processando convite...' : 'Preparando acesso...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Erro ao Aceitar Convite',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar Novamente'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ir para Login'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
