import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/reports/domain/models/report_submission.dart';
import 'package:salus/features/reports/domain/report_repository.dart';
import 'package:salus/features/reports/domain/submit_report_use_case.dart';

class _ReportRepositoryFake implements ReportRepository {
  ReportSubmission? submitted;

  @override
  Future<void> createReport(ReportSubmission report) async {
    submitted = report;
  }
}

void main() {
  test('normalizes report input before persisting it', () async {
    final repository = _ReportRepositoryFake();
    final useCase = SubmitReportUseCase(repository);

    await useCase(
      reporterId: 'citizen-1',
      targetType: ReportTarget.shelter,
      targetId: ' shelter-1 ',
      reason: ReportReason.unavailable,
      description: '  Refuge fermé  ',
    );

    expect(repository.submitted, isNotNull);
    expect(repository.submitted!.targetId, 'shelter-1');
    expect(repository.submitted!.description, 'Refuge fermé');
    expect(repository.submitted!.reporterId, 'citizen-1');
  });

  test('rejects an empty target before reaching the repository', () async {
    final repository = _ReportRepositoryFake();
    final useCase = SubmitReportUseCase(repository);

    expect(
      () => useCase(
        reporterId: 'citizen-1',
        targetType: ReportTarget.zone,
        targetId: ' ',
        reason: ReportReason.other,
      ),
      throwsArgumentError,
    );
    expect(repository.submitted, isNull);
  });

  test('requires a valid GPS location for road reports', () async {
    final repository = _ReportRepositoryFake();
    final useCase = SubmitReportUseCase(repository);

    expect(
      () => useCase(
        reporterId: 'citizen-1',
        targetType: ReportTarget.road,
        targetId: 'Position GPS',
        reason: ReportReason.blocked,
      ),
      throwsArgumentError,
    );
    expect(repository.submitted, isNull);

    const location = ReportLocation(latitude: -18.88, longitude: 47.51);
    await useCase(
      reporterId: 'citizen-1',
      targetType: ReportTarget.road,
      targetId: 'Position GPS',
      reason: ReportReason.blocked,
      targetLocation: location,
    );
    expect(repository.submitted!.targetLocation, location);
  });

  test('rejects coordinates outside geographic bounds', () async {
    final repository = _ReportRepositoryFake();
    final useCase = SubmitReportUseCase(repository);

    expect(
      () => useCase(
        reporterId: 'citizen-1',
        targetType: ReportTarget.road,
        targetId: 'Position GPS',
        reason: ReportReason.blocked,
        targetLocation: const ReportLocation(latitude: 91, longitude: 47.51),
      ),
      throwsArgumentError,
    );
    expect(repository.submitted, isNull);
  });
}
