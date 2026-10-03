import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/models/admin_portal_user.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_zone_point.dart';

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

  Future<void> updateReport({
    required String id,
    required String status,
    required String uid,
  });

  Future<void> validateShelter(String id, String uid);

  Future<void> setShelterValidationStatus(String id, String status, String uid);

  Future<void> createShelter({
    required String name,
    required String address,
    required int capacityTotal,
    required double latitude,
    required double longitude,
    required Map<String, bool> resources,
    required String userId,
  });

  Future<void> toggleZone(String id, {required bool isActive});

  Future<void> saveManualRiskZone({
    required String? id,
    required String name,
    required String description,
    required String disasterType,
    required String severity,
    required List<AdminZonePoint> geometry,
    required String userId,
    required String? organizationId,
  });

  Future<void> setUserActive(String id, {required bool isActive});

  Future<void> assignUserToOrganization(String userId, String organizationId);

  Future<void> removeUserOrganizationRole(String userId);

  Future<void> createOrganization({
    required String name,
    required String type,
    required String email,
    required String phone,
  });

  Future<void> updateOrganization({
    required String id,
    required String name,
    required String type,
    required String email,
    required String phone,
  });

  Future<void> setOrganizationActive(String id, {required bool isActive});
}
