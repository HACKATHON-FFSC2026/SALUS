import 'package:salus/features/reports/domain/models/report_submission.dart';

abstract interface class ReportRepository {
  Future<void> createReport(ReportSubmission report);
}
