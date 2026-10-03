import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';

/// Point de composition du dépôt consommé par l'interface admin.
final adminPortalUseCasesProvider = Provider<AdminPortalUseCases>(
  (ref) => AdminPortalUseCases(ref.watch(adminPortalRepositoryProvider)),
);
