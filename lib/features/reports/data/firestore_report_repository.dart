import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/report_entity.dart' as core;
import 'package:salus/features/reports/domain/report_repository.dart';
import 'package:salus/features/reports/domain/models/road_incident.dart';
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

  @override
  Stream<List<RoadIncident>> watchMyRoadIncidents(String reporterId) {
    return _firestore
        .collection(collection)
        .where('reporterId', isEqualTo: reporterId)
        .where('targetType', isEqualTo: core.ReportTargetType.road.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) {
                final report = core.Report.fromJson(document.data());
                final location = report.targetLocation;
                if (location == null ||
                    report.status == core.ReportStatus.resolved) {
                  return null;
                }
                return RoadIncident(
                  id: report.id,
                  latitude: location.latitude,
                  longitude: location.longitude,
                  reason: report.reason.name,
                  status: report.status.name,
                  description: report.description,
                  createdAt: report.createdAt,
                );
              })
              .whereType<RoadIncident>()
              .toList(growable: false),
        );
  }
}
