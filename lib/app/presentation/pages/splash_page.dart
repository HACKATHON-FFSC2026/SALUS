import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/widgets/app_logo.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';

/// Ecran d'entrée de l'application, pas une feature: il n'a ni domaine ni
/// couche data, il ne fait que router vers login ou main.
@RoutePage()
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(hasAccountProvider, (previous, next) {
      next.when(
        // Un écran de login raté vaut absence de compte: on n'y reste pas
        // bloqué sur le logo.
        error: (_, _) => context.router.replace(const LoginRoute()),
        data: (hasAccount) => context.router.replace(
          hasAccount
              ? (kIsWeb ? const OperationsPortalRoute() : const MainRoute())
              : const LoginRoute(),
        ),
        loading: () {},
      );
    });

    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: AppLogo(size: 200)),
    );
  }
}
