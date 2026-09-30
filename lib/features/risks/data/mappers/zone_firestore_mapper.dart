import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/zone_entity.dart';

class ZoneFirestoreMapper {
  static Zone fromFirestore(Map<String, dynamic> data, {String? documentId}) {
    return Zone(
      id: documentId ?? data['id'] as String? ?? '',
      type: _parseEnum(ZoneType.values, data['type']) ?? ZoneType.risk,
      disasterType: _parseEnum(DisasterType.values, data['disasterType']),
      geometry: (data['geometry'] as List<dynamic>? ?? [])
          .whereType<GeoPoint>()
          .map((g) => GeoPoint(g.latitude, g.longitude))
          .toList(),
      severity: _parseEnum(Severity.values, data['severity']),
      origin: _parseEnum(ZoneOrigin.values, data['origin']) ?? ZoneOrigin.manual,
      source: data['source'] as String? ?? 'unknown',
      createdBy: data['createdBy'] as String?,
      organizationId: data['organizationId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toFirestore(Zone zone) {
    return {
      'type': zone.type.name,
      'disasterType': zone.disasterType?.name,
      'geometry': zone.geometry
          .map((c) => GeoPoint(c.latitude, c.longitude))
          .toList(),
      'severity': zone.severity?.name,
      'origin': zone.origin.name,
      'source': zone.source,
      'createdBy': zone.createdBy,
      'organizationId': zone.organizationId,
      'isActive': zone.isActive,
      'startedAt': Timestamp.fromDate(zone.startedAt),
      if (zone.endedAt != null) 'endedAt': Timestamp.fromDate(zone.endedAt!),
    };
  }

  static T? _parseEnum<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}