import 'package:auto_route/auto_route.dart';
import 'package:salus/features/auth/pages/login_page.dart';
import 'package:salus/features/home/pages/main_page.dart';
import 'package:salus/features/splash/pages/splash_page.dart';

part 'app_router.gr.dart';

/// Racine de composition: le seul endroit autorisé à relier core et features.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: MainRoute.page),
  ];
}
