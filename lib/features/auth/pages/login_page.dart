import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:salus/core/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/widgets/app_logo.dart';
import 'package:salus/core/widgets/google_logo.dart';
import 'package:salus/core/utils/guest_session.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _showComingSoon(BuildContext context, String provider) {
    toastification.show(
      context: context,
      title: Text('$provider bientôt disponible'),
      type: ToastificationType.info,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  // ponytail: no auth logic yet — buttons route straight to MainRoute.
  void _enter(BuildContext context) {
    context.router.replace(const MainRoute());
  }

  Future<void> _enterAsGuest(BuildContext context) async {
    await setGuestMode();
    if (!context.mounted) return;
    context.router.replace(const MainRoute());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aide d\u2019urgence, refuges et alertes.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  _showComingSoon(context, 'Google');
                  _enter(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
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
              ElevatedButton(
                onPressed: () => _enterAsGuest(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sos,
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
}
