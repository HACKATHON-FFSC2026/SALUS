import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/report_entity.dart' as core;
import 'package:salus/features/reports/domain/report_repository.dart';
import 'package:salus/features/reports/domain/models/report_submission.dart';

class FirestoreReportRepository implements ReportRepository {
  const FirestoreReportRepository(this._firestore);

  static const collection = 'reports';

  final FirebaseFirestore _firestore;

  @override
  Future<void> createReport(ReportSubmission submission) async {
    final document = _firestore.collection(collection).doc();
    final report = core.Report(
      id: document.id,
      reporterId: submission.reporterId,
      targetType: switch (submission.targetType) {
        ReportTarget.shelter => core.ReportTargetType.shelter,
        ReportTarget.zone => core.ReportTargetType.zone,
        ReportTarget.road => core.ReportTargetType.road,
        ReportTarget.other => core.ReportTargetType.other,
      },
      targetId: submission.targetId,
      reason: switch (submission.reason) {
        ReportReason.unsafe => core.ReportReason.unsafe,
        ReportReason.unavailable => core.ReportReason.unavailable,
        ReportReason.blocked => core.ReportReason.blocked,
        ReportReason.other => core.ReportReason.other,
      },
      description: submission.description,
      targetLocation: submission.targetLocation == null
          ? null
          : GeoPoint(
              submission.targetLocation!.latitude,
              submission.targetLocation!.longitude,
            ),
      createdAt: submission.createdAt,
    );
    await document.set(report.toJson());
  }
}
