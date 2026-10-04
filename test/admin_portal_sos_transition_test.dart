import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/admin/domain/admin_portal_repository.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';

class _CapturingRepository implements AdminPortalRepository {
  String? updatedStatus;

  @override
  Future<void> updateSos({
    required String id,
    required String status,
    required String? assignedOrganizationId,
    required String? organizationId,
  }) async {
    updatedStatus = status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _CapturingRepository repository;
  late AdminPortalUseCases useCases;

  setUp(() {
    repository = _CapturingRepository();
    useCases = AdminPortalUseCases(repository);
  });

  test('an assigned SOS can be started by its organization', () async {
    await useCases.updateSos(
      id: 'sos-1',
      currentStatus: 'assigned',
      assignedOrganizationId: 'org-1',
      organizationId: 'org-1',
    );

    expect(repository.updatedStatus, 'inProgress');
  });

  test('an in-progress SOS can be resolved', () async {
    await useCases.updateSos(
      id: 'sos-1',
      currentStatus: 'inProgress',
      assignedOrganizationId: 'org-1',
      organizationId: 'org-1',
    );

    expect(repository.updatedStatus, 'resolved');
  });

  test('a waiting SOS must be assigned before the organization starts it', () {
    expect(
      () => useCases.updateSos(
        id: 'sos-1',
        currentStatus: 'waiting',
        assignedOrganizationId: null,
        organizationId: 'org-1',
      ),
      throwsArgumentError,
    );
    expect(repository.updatedStatus, isNull);
  });
}
