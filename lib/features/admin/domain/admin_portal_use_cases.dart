import 'package:salus/features/admin/domain/admin_portal_repository.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_dashboard_metrics.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/models/admin_portal_user.dart';
import 'package:salus/features/admin/domain/models/admin_zone_point.dart';
import 'package:salus/features/admin/domain/models/shelter_operational_status.dart';

/// Cas d'utilisation du portail. Les widgets ne portent aucune règle métier
/// et ne dépendent que de cette couche applicative.
class AdminPortalUseCases {
  const AdminPortalUseCases(this._repository);

  final AdminPortalRepository _repository;

  Stream<AdminPortalUser?> watchUser(String uid) => _repository.watchUser(uid);

  Stream<List<AdminPortalRecord>> watchCollection(
    AdminCollection collection, {
    required bool admin,
    String? organizationId,
  }) => _repository
      .watchCollection(
        collection,
        organizationId: admin ? null : organizationId,
      )
      .map((records) {
        if (collection == AdminCollection.shelters &&
            !admin &&
            organizationId != null) {
          return records
              .where((record) => record.organizationId == organizationId)
              .toList();
        }
        return records;
      });

  Future<AdminDashboardMetrics> loadMetrics({
    required bool admin,
    String? organizationId,
  }) async {
    final records = await _repository.loadDashboardRecords(
      admin: admin,
      organizationId: organizationId,
    );
    final sos = records[AdminCollection.sosAlerts] ?? const [];
    final reports = records[AdminCollection.reports] ?? const [];
    final organizations = records[AdminCollection.organizations] ?? const [];
    final zones = records[AdminCollection.zones] ?? const [];
    return AdminDashboardMetrics(
      activeSos: sos
          .where((record) => !['resolved', 'cancelled'].contains(record.status))
          .length,
      organizations: organizations
          .where((record) => record.verified && record.isActive == true)
          .length,
      shelters: records[AdminCollection.shelters]?.length ?? 0,
      users: records[AdminCollection.users]?.length ?? 0,
      openReports: reports.where((record) => record.status == 'open').length,
      activeZones: zones.where((record) => record.isActive == true).length,
    );
  }

  Future<void> verifyOrganization(String id, String uid) =>
      _repository.verifyOrganization(id, uid);

  Future<void> updateSos({
    required String id,
    required String? currentStatus,
    required String? assignedOrganizationId,
    required String? organizationId,
  }) => _repository.updateSos(
    id: id,
    status: currentStatus == 'assigned' || currentStatus == 'waiting'
        ? 'inProgress'
        : 'resolved',
    assignedOrganizationId: assignedOrganizationId,
    organizationId: organizationId,
  );

  Future<void> assignReportToOrganization(String id, String organizationId) =>
      _repository.assignReportToOrganization(id, organizationId);

  Future<void> assignShelterToOrganization(String id, String organizationId) =>
      _repository.assignShelterToOrganization(id, organizationId);

  Future<void> assignSosToOrganization(String id, String organizationId) =>
      _repository.assignSosToOrganization(id, organizationId);

  Future<void> updateReport({
    required String id,
    required String status,
    required String uid,
  }) => _repository.updateReport(id: id, status: status, uid: uid);

  Future<void> validateShelter(String id, String uid) =>
      _repository.validateShelter(id, uid);

  Future<void> setShelterValidationStatus(
    String id,
    String status,
    String uid,
  ) => _repository.setShelterValidationStatus(id, status, uid);

  Future<void> updateShelterOperations({
    required String id,
    required ShelterOperationalStatus status,
    required int capacityOccupied,
  }) => _repository.updateShelterOperations(
    id: id,
    status: status,
    capacityOccupied: capacityOccupied,
  );

  Future<void> createShelter({
    required String name,
    required String address,
    required int capacityTotal,
    required double latitude,
    required double longitude,
    required Map<String, bool> resources,
    required String userId,
  }) => _repository.createShelter(
    name: name,
    address: address,
    capacityTotal: capacityTotal,
    latitude: latitude,
    longitude: longitude,
    resources: resources,
    userId: userId,
  );

  Future<void> toggleZone(String id, {required bool isActive}) =>
      _repository.toggleZone(id, isActive: isActive);

  Future<void> saveManualRiskZone({
    required String? id,
    required String name,
    required String description,
    required String disasterType,
    required String severity,
    required List<AdminZonePoint> geometry,
    required String userId,
    required String? organizationId,
  }) => _repository.saveManualRiskZone(
    id: id,
    name: name,
    description: description,
    disasterType: disasterType,
    severity: severity,
    geometry: geometry,
    userId: userId,
    organizationId: organizationId,
  );

  Future<void> setUserActive(String id, {required bool isActive}) =>
      _repository.setUserActive(id, isActive: isActive);

  Future<void> assignUserToOrganization(String userId, String organizationId) =>
      _repository.assignUserToOrganization(userId, organizationId);

  Future<void> removeUserOrganizationRole(String userId) =>
      _repository.removeUserOrganizationRole(userId);

  Future<void> createOrganization({
    required String name,
    required String type,
    required String email,
    required String phone,
  }) => _repository.createOrganization(
    name: name,
    type: type,
    email: email,
    phone: phone,
  );

  Future<void> updateOrganization({
    required String id,
    required String name,
    required String type,
    required String email,
    required String phone,
  }) => _repository.updateOrganization(
    id: id,
    name: name,
    type: type,
    email: email,
    phone: phone,
  );

  Future<void> setOrganizationActive(String id, {required bool isActive}) =>
      _repository.setOrganizationActive(id, isActive: isActive);
}
