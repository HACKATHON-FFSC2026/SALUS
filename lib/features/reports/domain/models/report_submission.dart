enum ReportTarget { shelter, zone, road, other }

enum ReportReason { unsafe, unavailable, blocked, other }

class ReportLocation {
  const ReportLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class ReportSubmission {
  const ReportSubmission({
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.description,
    this.targetLocation,
  });

  final String reporterId;
  final ReportTarget targetType;
  final String targetId;
  final ReportReason reason;
  final String? description;
  final ReportLocation? targetLocation;
  final DateTime createdAt;
}
