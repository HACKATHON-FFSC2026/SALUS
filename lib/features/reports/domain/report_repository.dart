import 'package:salus/features/reports/domain/models/road_incident.dart';
import 'package:salus/features/reports/domain/models/report_submission.dart';

abstract interface class ReportRepository {
  Future<void> createReport(ReportSubmission report);

  Stream<List<RoadIncident>> watchMyRoadIncidents(String reporterId);
}
