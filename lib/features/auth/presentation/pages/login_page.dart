import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/widgets/app_logo.dart';
import 'package:salus/core/widgets/google_logo.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/auth/presentation/state/auth_state.dart';
import 'package:toastification/toastification.dart';

@RoutePage()
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Un seul endroit réagit à l'état: message puis navigation. La page ne
    // decisionne plus du sort de l'authentification.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        if (next.warningMessage != null) {
          _notify(context, next.warningMessage!, ToastificationType.warning);
        }
        context.router.replace(
          kIsWeb ? const OperationsPortalRoute() : const MainRoute(),
        );
        return;
      }
      if (next.status == AuthStatus.failure && next.errorMessage != null) {
        _notify(context, next.errorMessage!, ToastificationType.error);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: AppLogo(size: 140)),
              const SizedBox(height: 16),
              Text(
                'SALUS',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aide d’urgence, refuges et alertes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (auth.isRegistering) ...[
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Finalisation de votre compte…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Choisissez votre mode d’accès',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kIsWeb
                    ? 'Connectez-vous avec votre compte d’équipe pour accéder au portail web.'
                    : 'Google synchronise votre profil. Le mode invité donne accès à l’application sans compte.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: auth.isBusy
                    ? null
                    : () => ref.read(authProvider.notifier).signInWithGoogle(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleLogo(size: 20),
                    SizedBox(width: 10),
                    Text('Continuer avec Google'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!kIsWeb)
                ElevatedButton(
                  onPressed: auth.isBusy
                      ? null
                      : () => ref.read(authProvider.notifier).continueAsGuest(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continuer sans connexion'),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _notify(BuildContext context, String message, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}
