import 'package:cloud_firestore/cloud_firestore.dart';

enum DistressType { medical, security, accident, fire, other }
enum SOSStatus { waiting, inProgress, resolved, cancelled }

class SOSAlert {
  final String id;
  final String userId;
  final GeoPoint location;
  final DistressType distressType;
  final String? description;
  final SOSStatus status;
  final int respondersCount;
  final DateTime createdAt;
  final double? distanceInKm; // Champ optionnel pour le tri local

  SOSAlert({
    required this.id,
    required this.userId,
    required this.location,
    this.distressType = DistressType.other,
    this.description,
    required this.status,
    required this.respondersCount,
    required this.createdAt,
    this.distanceInKm,
  });

  SOSAlert copyWith({double? distanceInKm, SOSStatus? status, int? respondersCount}) {
    return SOSAlert(
      id: id,
      userId: userId,
      location: location,
      distressType: distressType,
      description: description,
      status: status ?? this.status,
      respondersCount: respondersCount ?? this.respondersCount,
      createdAt: createdAt,
      distanceInKm: distanceInKm ?? this.distanceInKm,
    );
  }

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      location: json['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      distressType: DistressType.values.firstWhere(
        (e) => e.name == json['distressType'],
        orElse: () => DistressType.other,
      ),
      description: json['description'],
      status: SOSStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SOSStatus.waiting,
      ),
      respondersCount: json['respondersCount'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'location': location,
      'distressType': distressType.name,
      'description': description,
      'status': status.name,
      'respondersCount': respondersCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}