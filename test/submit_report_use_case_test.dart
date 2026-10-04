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
}
