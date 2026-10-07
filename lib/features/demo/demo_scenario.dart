import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/entities.dart';

/// Côté de la cellule de quantisation du centre (≈2,2 km). Les jurys dans le
/// même secteur voient le même scénario, et un frémissement GPS ne le
/// régénère pas.
const double kDemoCenterCell = 0.02;

/// Refuges validés et zones à risque fictifs, placés autour d'un point réel.
class DemoScenario {
  const DemoScenario({required this.shelters, required this.zones});

  final List<Shelter> shelters;
  final List<Zone> zones;
}

/// Construit un scénario déterministe autour de [latitude]/[longitude].
///
/// Déterministe = même cellule géographique, mêmes données : deux appareils
/// voisins affichent la même chose. Aucune écriture Firestore.
DemoScenario buildDemoScenario({
  required double latitude,
  required double longitude,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final rng = math.Random(_seedFor(latitude, longitude));

  final shelters = <Shelter>[];
  final shelterCount = 4 + rng.nextInt(3); // 4 à 6
  for (var i = 0; i < shelterCount; i++) {
    final point = _offset(
      latitude,
      longitude,
      distanceKm: 0.3 + rng.nextDouble() * 2.7,
      bearingDeg: rng.nextDouble() * 360,
    );
    final total = 40 + rng.nextInt(261);
    final status = _pickShelterStatus(rng);
    final occupied = switch (status) {
      ShelterStatus.open => (total * (0.1 + rng.nextDouble() * 0.3)).round(),
      ShelterStatus.almostFull =>
        (total * (0.85 + rng.nextDouble() * 0.1)).round(),
      ShelterStatus.full => total,
      ShelterStatus.closed => 0,
    };
    shelters.add(
      Shelter(
        id: 'demo-shelter-${i + 1}',
        name: _shelterNames[i % _shelterNames.length],
        location: point,
        address: _streets[i % _streets.length],
        capacityTotal: total,
        capacityOccupied: occupied,
        status: status,
        resources: ShelterResources(
          water: true,
          food: rng.nextBool(),
          electricity: rng.nextBool(),
          medicalKit: rng.nextBool(),
        ),
        createdBy: 'demo',
        validationStatus: ValidationStatus.validated,
        createdAt: reference.subtract(Duration(days: 3 + rng.nextInt(30))),
        updatedAt: reference.subtract(Duration(hours: rng.nextInt(24))),
      ),
    );
  }

  final zones = <Zone>[];
  final zoneCount = 1 + rng.nextInt(2); // 1 à 2
  for (var i = 0; i < zoneCount; i++) {
    final type = _disasterTypes[rng.nextInt(_disasterTypes.length)];
    final center = _offset(
      latitude,
      longitude,
      distanceKm: 1.0 + rng.nextDouble() * 2.0,
      bearingDeg: rng.nextDouble() * 360,
    );
    zones.add(
      Zone(
        id: 'demo-zone-${i + 1}',
        type: ZoneType.risk,
        disasterType: type,
        geometry: _circle(
          center.latitude,
          center.longitude,
          radiusKm: 0.7 + rng.nextDouble() * 0.8,
        ),
        severity: rng.nextBool() ? Severity.high : Severity.critical,
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        description: _zoneDescription(type),
        isActive: true,
        startedAt: reference.subtract(Duration(hours: 1 + rng.nextInt(20))),
      ),
    );
  }

  return DemoScenario(shelters: shelters, zones: zones);
}

const _shelterNames = [
  'Gymnase municipal',
  'Salle polyvalente',
  'Centre sportif',
  'École primaire',
  'Maison communale',
  'Lycée',
  'Centre culturel',
  'Stade municipal',
];

const _streets = [
  'Avenue centrale',
  'Rue du Marché',
  'Boulevard des Écoles',
  'Rue des Acacias',
  'Place de la République',
  "Rue de l'Église",
];

const _disasterTypes = [
  DisasterType.flood,
  DisasterType.cyclone,
  DisasterType.landslide,
];

String _zoneDescription(DisasterType type) => switch (type) {
  DisasterType.flood =>
    'Crue signalée : montée des eaux dans le secteur, évitez les abords.',
  DisasterType.cyclone =>
    'Vents cycloniques annoncés. Restez à l\'abri et suivez les consignes.',
  DisasterType.landslide =>
    'Risque de glissement de terrain après les fortes pluies.',
  _ => 'Zone à risque active à proximité.',
};

ShelterStatus _pickShelterStatus(math.Random rng) {
  final v = rng.nextDouble();
  if (v < 0.6) return ShelterStatus.open;
  if (v < 0.85) return ShelterStatus.almostFull;
  return ShelterStatus.full;
}

/// Hash spatial déterministe : `Object.hash` est randomisé par isolate, ce qui
/// ferait bouger le scénario à chaque lancement. Ici, mêmes coordonnées =>
/// même graine, à vie.
int _seedFor(double latitude, double longitude) {
  final latCell = (latitude / kDemoCenterCell).round();
  final lngCell = (longitude / kDemoCenterCell).round();
  return (latCell * 73856093) ^ (lngCell * 19349663);
}

/// Point situé à [distanceKm] du centre, dans la direction [bearingDeg].
/// Approxime les degrés par kilomètre : suffisant à l'échelle d'une ville.
GeoPoint _offset(
  double latitude,
  double longitude, {
  required double distanceKm,
  required double bearingDeg,
}) {
  const kmPerDegLat = 111.32;
  final kmPerDegLng =
      kmPerDegLat * math.cos(latitude * math.pi / 180).abs().clamp(0.01, 1.0);
  final bearing = bearingDeg * math.pi / 180;
  return GeoPoint(
    latitude + distanceKm * math.cos(bearing) / kmPerDegLat,
    longitude + distanceKm * math.sin(bearing) / kmPerDegLng,
  );
}

/// Polygone fermé approximant un cercle (>= 3 sommets, requis par la carte).
List<GeoPoint> _circle(
  double latitude,
  double longitude, {
  required double radiusKm,
  int points = 16,
}) {
  return [
    for (var i = 0; i < points; i++)
      _offset(
        latitude,
        longitude,
        distanceKm: radiusKm,
        bearingDeg: i * 360 / points,
      ),
  ];
}
