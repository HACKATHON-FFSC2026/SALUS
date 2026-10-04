class RoadIncident {
  const RoadIncident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.description,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String reason;
  final String status;
  final String? description;
  final DateTime createdAt;
}
