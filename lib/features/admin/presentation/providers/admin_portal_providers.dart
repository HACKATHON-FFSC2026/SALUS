import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/sources/firestore_client.dart';
import 'package:salus/features/admin/data/firestore_admin_portal_repository.dart';
import 'package:salus/features/admin/domain/admin_portal_repository.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';

/// Point de composition du dépôt consommé par l'interface admin.
final adminPortalRepositoryProvider = Provider<AdminPortalRepository>(
  (ref) => FirestoreAdminPortalRepository(ref.watch(firestoreProvider)),
);

final adminPortalUseCasesProvider = Provider<AdminPortalUseCases>(
  (ref) => AdminPortalUseCases(ref.watch(adminPortalRepositoryProvider)),
);
