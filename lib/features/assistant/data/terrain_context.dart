import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/utils/geo_math.dart';

/// Contexte terrain compact à joindre au copilote.
///
/// Construit à partir des mêmes providers que la carte (données de
/// démonstration comprises). L'IA, qui ne lit que le backend, peut ainsi citer
/// ce que l'utilisateur voit réellement. Une seule ligne, bornée : les plus
/// proches, un rayon limité, des libellés courts.
String? buildTerrainContext({
  required double originLatitude,
  required double originLongitude,
  required List<Shelter> shelters,
  required List<Zone> zones,
  int maxShelters = 3,
  int maxZones = 3,
  double shelterRadiusKm = 5,
  double zoneRadiusKm = 15,
}) {
  final origin = GeoPoint(originLatitude, originLongitude);
  final nearShelters =
      shelters
          .map((s) => (s, GeoMath.distanceKm(origin, s.location)))
          .where((e) => e.$2 <= shelterRadiusKm)
          .toList()
        ..sort((a, b) => a.$2.compareTo(b.$2));

  final seen = <String>{};
  final nearZones = <(Zone, double)>[];
  for (final zone in zones) {
    if (!zone.isActive || zone.type != ZoneType.risk) continue;
    if (zone.geometry.isEmpty || !seen.add(zone.id)) continue;
    final center = GeoMath.centroid(zone.geometry);
    final distance = GeoMath.distanceKm(
      origin,
      GeoPoint(center.latitude, center.longitude),
    );
    if (distance <= zoneRadiusKm) nearZones.add((zone, distance));
  }
  nearZones.sort((a, b) => a.$2.compareTo(b.$2));

  if (nearShelters.isEmpty && nearZones.isEmpty) return null;

  final shelterText = nearShelters
      .take(maxShelters)
      .map((e) {
        final shelter = e.$1;
        final free = (shelter.capacityTotal - shelter.capacityOccupied).clamp(
          0,
          shelter.capacityTotal,
        );
        return '${shelter.name} (${_distance(e.$2)}, '
            '${_shelterStatus(shelter.status)}, $free pl.)';
      })
      .join('; ');

  final zoneText = nearZones
      .take(maxZones)
      .map(
        (e) =>
            '${_disaster(e.$1.disasterType)} '
            '(${_severity(e.$1.severity)}, ${_distance(e.$2)})',
      )
      .join('; ');

  final parts = <String>[
    if (shelterText.isNotEmpty) 'Refuges proches: $shelterText',
    if (zoneText.isNotEmpty) 'Zones à risque: $zoneText',
  ];
  return '[Terrain SALUS] ${parts.join('. ')}.';
}

String _distance(double km) => km < 1
    ? '${(km * 1000).round()} m'
    : '${km.toStringAsFixed(1)} km';

String _shelterStatus(ShelterStatus status) => switch (status) {
  ShelterStatus.open => 'ouvert',
  ShelterStatus.almostFull => 'presque complet',
  ShelterStatus.full => 'complet',
  ShelterStatus.closed => 'fermé',
};

String _disaster(DisasterType? type) => switch (type) {
  DisasterType.earthquake => 'Séisme',
  DisasterType.tsunami => 'Tsunami',
  DisasterType.cyclone => 'Cyclone',
  DisasterType.flood => 'Inondation',
  DisasterType.landslide => 'Glissement de terrain',
  DisasterType.volcano => 'Volcan',
  _ => 'Catastrophe',
};

String _severity(Severity? severity) => switch (severity) {
  Severity.low => 'faible',
  Severity.medium => 'modérée',
  Severity.high => 'élevée',
  Severity.critical => 'critique',
  null => 'inconnue',
};
