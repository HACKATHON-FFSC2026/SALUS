enum ReportTarget { shelter, zone, road, other }

enum ReportReason { unsafe, unavailable, blocked, other }

class ReportSubmission {
  const ReportSubmission({
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.description,
  });

  final String reporterId;
  final ReportTarget targetType;
  final String targetId;
  final ReportReason reason;
  final String? description;
  final DateTime createdAt;
}
