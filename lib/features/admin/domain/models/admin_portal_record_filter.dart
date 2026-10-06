import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';

String adminRecordStatus(
  AdminCollection collection,
  AdminPortalRecord record,
) => switch (collection) {
  AdminCollection.zones =>
    record.isActive == false
        ? record.zoneType == 'risk' && record.zoneOrigin == 'manual'
              ? 'closed'
              : 'inactive'
        : 'active',
  AdminCollection.shelters => record.validationStatus ?? 'pending',
  AdminCollection.organizations =>
    record.isActive != true
        ? 'suspended'
        : record.verified
        ? 'verified'
        : 'pending',
  AdminCollection.users => record.isActive == false ? 'inactive' : 'active',
  AdminCollection.sosAlerts ||
  AdminCollection.reports => record.status ?? 'unknown',
};

DateTime? adminRecordDate(AdminPortalRecord record) =>
    record.createdAt ??
    record.startedAt ??
    record.verifiedAt ??
    record.locationUpdatedAt;

List<AdminPortalRecord> filterAdminRecords({
  required AdminCollection collection,
  required List<AdminPortalRecord> records,
  String query = '',
  String? status,
  DateTime? startDate,
  DateTime? endDate,
  bool newestFirst = true,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final endExclusive = endDate == null
      ? null
      : DateTime(endDate.year, endDate.month, endDate.day + 1);
  final filtered = records.where((record) {
    if (status != null && adminRecordStatus(collection, record) != status) {
      return false;
    }
    final date = adminRecordDate(record);
    if (startDate != null &&
        (date == null ||
            date.isBefore(
              DateTime(startDate.year, startDate.month, startDate.day),
            ))) {
      return false;
    }
    if (endExclusive != null && (date == null || !date.isBefore(endExclusive))) {
      return false;
    }
    if (normalizedQuery.isEmpty) return true;
    return _searchableValues(record, collection).any(
      (value) => value.toLowerCase().contains(normalizedQuery),
    );
  }).toList();

  filtered.sort((left, right) {
    final leftDate = adminRecordDate(left) ?? DateTime(0);
    final rightDate = adminRecordDate(right) ?? DateTime(0);
    final comparison = leftDate.compareTo(rightDate);
    return newestFirst ? -comparison : comparison;
  });
  return filtered;
}

List<String> _searchableValues(
  AdminPortalRecord record,
  AdminCollection collection,
) => [
  record.id,
  record.title,
  record.displayName,
  record.name,
  record.description,
  record.email,
  record.contactEmail,
  record.contactPhone,
  record.userId,
  record.reporterId,
  record.address,
  record.reason,
  record.type,
  record.targetType,
  record.targetId,
  record.status,
  record.validationStatus,
  record.safetyStatus,
  record.distressType,
  record.organizationId,
  record.assignedOrganizationId,
  record.createdBy,
  record.source,
  record.zoneType,
  record.zoneOrigin,
  record.disasterType,
  record.severity,
  ...record.roles,
  adminRecordStatus(collection, record),
].whereType<String>().toList();
