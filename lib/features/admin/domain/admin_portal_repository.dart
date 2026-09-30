import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/models/admin_portal_user.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';

abstract interface class AdminPortalRepository {
  Stream<AdminPortalUser?> watchUser(String uid);

  Stream<List<AdminPortalRecord>> watchCollection(AdminCollection collection);

  Future<Map<AdminCollection, List<AdminPortalRecord>>> loadDashboardRecords({
    required bool admin,
  });

  Future<void> verifyOrganization(String id, String uid);

  Future<void> updateSos({
    required String id,
    required String status,
    required String? assignedOrganizationId,
    required String uid,
  });

  Future<void> validateShelter(String id, String uid);

  Future<void> toggleZone(String id, {required bool isActive});

  Future<void> setUserActive(String id, {required bool isActive});

  Future<void> createOrganization({
    required String name,
    required String email,
    required String phone,
  });
}
