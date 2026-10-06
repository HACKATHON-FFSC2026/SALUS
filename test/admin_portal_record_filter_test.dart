import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record_filter.dart';

AdminPortalRecord _record(
  String id, {
  required DateTime createdAt,
  String status = 'waiting',
  String? email,
}) => AdminPortalRecord(
  id: id,
  createdAt: createdAt,
  status: status,
  email: email,
);

void main() {
  final records = [
    _record(
      'sos-new',
      createdAt: DateTime(2026, 10, 4, 12),
      status: 'inProgress',
      email: 'team@example.com',
    ),
    _record('sos-old', createdAt: DateTime(2026, 10, 2, 12), status: 'waiting'),
    _record(
      'sos-resolved',
      createdAt: DateTime(2026, 10, 3, 12),
      status: 'resolved',
    ),
  ];

  test('sorts newest first by default and supports oldest first', () {
    expect(
      filterAdminRecords(
        collection: AdminCollection.sosAlerts,
        records: records,
      ).map((record) => record.id),
      ['sos-new', 'sos-resolved', 'sos-old'],
    );
    expect(
      filterAdminRecords(
        collection: AdminCollection.sosAlerts,
        records: records,
        newestFirst: false,
      ).map((record) => record.id),
      ['sos-old', 'sos-resolved', 'sos-new'],
    );
  });

  test(
    'combines case-insensitive search, status and inclusive date filters',
    () {
      expect(
        filterAdminRecords(
          collection: AdminCollection.sosAlerts,
          records: records,
          query: 'TEAM@EXAMPLE',
          status: 'inProgress',
          startDate: DateTime(2026, 10, 4),
          endDate: DateTime(2026, 10, 4),
        ).map((record) => record.id),
        ['sos-new'],
      );
    },
  );

  test('derives organization and user statuses for filtering', () {
    final organization = AdminPortalRecord(
      id: 'org-1',
      verified: true,
      isActive: true,
    );
    final suspendedOrganization = AdminPortalRecord(
      id: 'org-2',
      verified: true,
      isActive: false,
    );
    final user = AdminPortalRecord(id: 'user-1', isActive: false);

    expect(
      adminRecordStatus(AdminCollection.organizations, organization),
      'verified',
    );
    expect(
      adminRecordStatus(AdminCollection.organizations, suspendedOrganization),
      'suspended',
    );
    expect(adminRecordStatus(AdminCollection.users, user), 'inactive');
  });
}
