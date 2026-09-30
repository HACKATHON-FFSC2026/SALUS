import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:salus/app/presentation/pages/splash_page.dart';
import 'package:salus/features/auth/presentation/pages/login_page.dart';
import 'package:salus/features/home/presentation/pages/main_page.dart';
import 'package:salus/features/admin/presentation/pages/operations_portal_page.dart';
import 'package:salus/features/shelters/presentation/pages/create_shelter_page.dart';
import 'package:salus/features/shelters/presentation/pages/shelter_location_picker_page.dart';

part 'app_router.gr.dart';

/// Racine de composition: le seul endroit autorisé à relier core et features.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: MainRoute.page),
    AutoRoute(page: OperationsPortalRoute.page),
    AutoRoute(page: CreateShelterRoute.page),
    AutoRoute(page: ShelterLocationPickerRoute.page),
  ];
}
