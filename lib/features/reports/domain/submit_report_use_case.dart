import 'package:salus/features/reports/domain/report_repository.dart';
import 'package:salus/features/reports/domain/models/report_submission.dart';

class SubmitReportUseCase {
  const SubmitReportUseCase(this._repository);

  final ReportRepository _repository;

  Future<void> call({
    required String reporterId,
    required ReportTarget targetType,
    required String targetId,
    required ReportReason reason,
    String? description,
    ReportLocation? targetLocation,
  }) {
    final cleanReporterId = reporterId.trim();
    final cleanTargetId = targetId.trim();
    if (cleanReporterId.isEmpty) {
      throw ArgumentError.value(reporterId, 'reporterId', 'Must not be empty');
    }
    if (cleanTargetId.isEmpty) {
      throw ArgumentError.value(targetId, 'targetId', 'Must not be empty');
    }
    if (targetType == ReportTarget.road && targetLocation == null) {
      throw ArgumentError.value(
        targetLocation,
        'targetLocation',
        'Road reports require a location',
      );
    }
    if (targetLocation != null &&
        (targetLocation.latitude < -90 ||
            targetLocation.latitude > 90 ||
            targetLocation.longitude < -180 ||
            targetLocation.longitude > 180)) {
      throw ArgumentError.value(
        targetLocation,
        'targetLocation',
        'Coordinates are out of range',
      );
    }

    return _repository.createReport(
      ReportSubmission(
        reporterId: cleanReporterId,
        targetType: targetType,
        targetId: cleanTargetId,
        reason: reason,
        description: _validatedDescription(description),
        targetLocation: targetLocation,
        createdAt: DateTime.now(),
      ),
    );
  }

  String? _validatedDescription(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.length > 4000) {
      throw ArgumentError.value(value, 'description', 'Maximum 4000 characters');
    }
    return trimmed;
  }
}
