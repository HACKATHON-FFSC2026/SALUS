import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/utils/geo_grid.dart';

enum DistressType { medical, security, accident, fire, other }

enum SOSStatus {
  waiting,
  inProgress,
  resolved,
  cancelled;

  bool get isActive => this == waiting || this == inProgress;
  bool get isOver => !isActive;
}

class SOSAlert {
  SOSAlert({
    required this.id,
    required this.userId,
    required this.location,
    required this.distressType,
    required this.status,
    required this.createdAt,
    this.description,
    this.responderIds = const [],
    this.locationUpdatedAt,
    this.distanceInKm,
  });

  final String id;
  final String userId;
  final GeoPoint location;
  final DistressType distressType;
  final String? description;
  final SOSStatus status;

  /// Source de vérité du nombre d'intervenants. Un uid n'y entre qu'une fois:
  /// `arrayUnion` côté écriture, `hasOnly` côté règles Firestore.
  final List<String> responderIds;

  final DateTime createdAt;

  /// Dernière position connue, rafraîchie pendant que l'alerte est active.
  final DateTime? locationUpdatedAt;

  /// Calculé côté client pour le tri par proximité. Jamais persisté.
  final double? distanceInKm;

  int get respondersCount => responderIds.length;

  bool get isActive => status.isActive;

  SOSAlert copyWith({
    String? id,
    String? userId,
    GeoPoint? location,
    DistressType? distressType,
    SOSStatus? status,
    DateTime? createdAt,
    String? description,
    bool clearDescription = false,
    List<String>? responderIds,
    DateTime? locationUpdatedAt,
    double? distanceInKm,
    bool clearDistance = false,
  }) {
    return SOSAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      distressType: distressType ?? this.distressType,
      description: clearDescription ? null : description ?? this.description,
      status: status ?? this.status,
      responderIds: responderIds ?? this.responderIds,
      createdAt: createdAt ?? this.createdAt,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      distanceInKm: clearDistance ? null : distanceInKm ?? this.distanceInKm,
    );
  }

  /// Levée si le document est illisible. Un SOS sans position est pire
  /// qu'un SOS absent : on l'ignore plutôt que de le géolocaliser à (0, 0).
  factory SOSAlert.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('Document SOS sans données');
    }

    final rawLocation = json['location'];
    if (rawLocation is! GeoPoint) {
      throw FormatException('Document SOS sans position exploitable: $rawLocation');
    }

    return SOSAlert(
      id: (json['id'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      location: rawLocation,
      distressType: _enumByName(
        DistressType.values,
        json['distressType'],
        DistressType.other,
      ),
      description: json['description'] as String?,
      status: _enumByName(
        SOSStatus.values,
        json['status'],
        SOSStatus.waiting,
      ),
      responderIds: _stringList(json['responderIds']),
      createdAt: _timestamp(json['createdAt']) ?? DateTime.now(),
      locationUpdatedAt: _timestamp(json['locationUpdatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'location': location,
      // Dénormalisé: Firestore ne sait pas filtrer une boîte englobante sur
      // un GeoPoint. Le tri grossier se fait sur cette cellule, la distance
      // fine reste côté client.
      'geoCell': GeoGrid.cellFor(location.latitude, location.longitude),
      'distressType': distressType.name,
      'description': description,
      'status': status.name,
      'responderIds': responderIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'locationUpdatedAt': locationUpdatedAt == null
          ? null
          : Timestamp.fromDate(locationUpdatedAt!),
    };
  }

  /// Distance orthodromique depuis [origin], pour le tri par proximité.
  SOSAlert withDistanceFrom({required double latitude, required double longitude}) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(latitude - location.latitude);
    final dLon = _radians(longitude - location.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radians(location.latitude)) *
            math.cos(_radians(latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    // 2 * atan2(sqrt(h), sqrt(1-h)) est la forme stable de l'arcsin(2*sqrt(h)).
    final km = 2 * earthRadiusKm * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return copyWith(distanceInKm: km);
  }
}

double _radians(double degrees) => degrees * math.pi / 180.0;

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

DateTime? _timestamp(Object? raw) => raw is Timestamp ? raw.toDate() : null;

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<String>().toList(growable: false);
}