import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/app_router.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_spacing.dart";
import "auth_provider.dart";
import "auth_text_field.dart";

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
    if (ok && mounted) {
      context.goNamed(AppRouteNames.organizationSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);
    final errorMsg = _errorMessage(auth.error);

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Row(
        children: [
          _BrandPanel(colors: colors),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colors.panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: colors.textPrimary.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Criar conta",
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            "Entre no escritório virtual.",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 28),
                          AuthTextField(
                            controller: _nameCtrl,
                            colors: colors,
                            label: "Seu nome",
                            hint: "Como quer ser chamado?",
                            validator: (v) {
                              if (v == null || v.trim().length < 2) {
                                return "Mínimo 2 caracteres";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AuthTextField(
                            controller: _emailCtrl,
                            colors: colors,
                            label: "E-mail",
                            hint: "seu@email.com",
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Informe seu e-mail";
                              }
                              if (!v.contains("@")) return "E-mail inválido";
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AuthTextField(
                            controller: _passwordCtrl,
                            colors: colors,
                            label: "Senha",
                            hint: "Mínimo 6 caracteres",
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                                color: colors.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return "Mínimo 6 caracteres";
                              }
                              return null;
                            },
                          ),
                          if (errorMsg != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 16, color: colors.red),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      errorMsg,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 44,
                            child: FilledButton(
                              onPressed: auth.isLoading ? null : _submit,
                              child: auth.isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.textInverse,
                                      ),
                                    )
                                  : const Text("Criar conta"),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Já tem conta? ",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    context.goNamed(AppRouteNames.login),
                                child: Text(
                                  "Entrar",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.brandPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _errorMessage(String? code) {
    if (code == null) return null;
    return switch (code) {
      "identity.user.email_already_taken" => "Este e-mail já está em uso.",
      "identity.user.display_name_too_short" => "Nome muito curto.",
      _ => "Erro ao criar conta. Tente novamente.",
    };
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.brandPrimary, colors.brandSecondary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              "Love+Robot",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Crie sua conta e entre no\nescrittório virtual agora mesmo.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textInverse.withValues(alpha: 0.85),
                    height: 1.6,
                  ),
            ),
            const Spacer(),
            _Step(colors: colors, number: "1", label: "Crie sua conta"),
            const SizedBox(height: AppSpacing.xl),
            _Step(
              colors: colors,
              number: "2",
              label: "Crie ou entre em uma organização",
            ),
            const SizedBox(height: AppSpacing.xl),
            _Step(
              colors: colors,
              number: "3",
              label: "Explore o escritório virtual",
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.colors,
    required this.number,
    required this.label,
  });
  final AppColors colors;
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.textInverse.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: colors.textInverse,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textInverse.withValues(alpha: 0.9),
              ),
        ),
      ],
    );
  }
}
