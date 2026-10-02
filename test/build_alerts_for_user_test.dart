import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/features/alerts/domain/usecases/build_alerts_for_user.dart';
import 'package:salus/features/risks/domain/services/zone_geofence_service.dart';

/// Mock simple de ZoneGeofenceService pour contrôler 'isUserInZone' dans les tests
class MockZoneGeofenceService implements ZoneGeofenceService {
  final Map<String, bool> insideAnswers = {};

  void setInside(String zoneId, bool isInside) {
    insideAnswers[zoneId] = isInside;
  }

  @override
  bool isUserInZone(GeoPoint userPosition, Zone zone) {
    return insideAnswers[zone.id] ?? false;
  }
}

void main() {
  late MockZoneGeofenceService mockGeofence;
  late BuildAlertsForUser useCase;

  // Position de l'utilisateur de référence (ex: Antananarivo)
  const userPosition = GeoPoint(-18.8792, 47.5079);
  final testDate = DateTime(2026, 10, 1);

  // Polygone factice valide (> 2 points) autour ou près d'Antananarivo
  final dummyGeometry = [
    const GeoPoint(-18.8, 47.5),
    const GeoPoint(-18.8, 47.6),
    const GeoPoint(-18.9, 47.5),
  ];

  setUp(() {
    mockGeofence = MockZoneGeofenceService();
    useCase = BuildAlertsForUser(mockGeofence);
  });

  group('BuildAlertsForUser Tests', () {
    test('devrait générer une alerte quand l\'utilisateur est À L\'INTÉRIEUR d\'une zone', () {
      final zoneInside = Zone(
        id: 'zone-1',
        isActive: true,
        type: ZoneType.risk,
        severity: Severity.high,
        disasterType: DisasterType.cyclone,
        geometry: dummyGeometry,
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        startedAt: testDate,
      );

      mockGeofence.setInside('zone-1', true);

      final alerts = useCase(
        position: userPosition,
        zones: [zoneInside],
      );

      expect(alerts.length, 1);
      final alert = alerts.first;
      expect(alert.userInsideZone, isTrue);
      expect(alert.title, contains('Alerte rouge'));
      expect(alert.message, contains('Vous vous trouvez dans la zone'));
    });

    test('devrait générer une alerte quand l\'utilisateur est HORS ZONE mais dans le rayon de vigilance', () {
      final zoneNearby = Zone(
        id: 'zone-2',
        isActive: true,
        type: ZoneType.risk,
        severity: Severity.medium,
        disasterType: DisasterType.cyclone,
        geometry: dummyGeometry,
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        startedAt: testDate,
      );

      mockGeofence.setInside('zone-2', false);

      final alerts = useCase(
        position: userPosition,
        zones: [zoneNearby],
      );

      expect(alerts.length, 1);
      final alert = alerts.first;
      expect(alert.userInsideZone, isFalse);
      expect(alert.title, contains('Alerte orange'));
      expect(alert.message, contains('se trouve à'));
    });

    test('devrait FILTRER les zones inactives, non-risque, de sévérité faible ou géométrie insuffisante', () {
      final inactiveZone = Zone(
        id: 'z-inactive',
        isActive: false,
        type: ZoneType.risk,
        severity: Severity.high,
        geometry: dummyGeometry,
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        startedAt: testDate,
      );

      final lowSeverityZone = Zone(
        id: 'z-low',
        isActive: true,
        type: ZoneType.risk,
        severity: Severity.low,
        geometry: dummyGeometry,
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        startedAt: testDate,
      );

      final invalidGeoZone = Zone(
        id: 'z-invalid-geo',
        isActive: true,
        type: ZoneType.risk,
        severity: Severity.high,
        geometry: [const GeoPoint(0, 0), const GeoPoint(1, 1)], // < 3 points
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        startedAt: testDate,
      );

      final alerts = useCase(
        position: userPosition,
        zones: [inactiveZone, lowSeverityZone, invalidGeoZone],
      );

      expect(alerts, isEmpty);
    });

    test('devrait détecter qu\'un événement SE RAPPROCHE (approaching = true)', () {
      final zoneApproaching = Zone(
        id: 'zone-3',
        isActive: true,
        type: ZoneType.risk,
        severity: Severity.high,
        disasterType: DisasterType.flood,
        geometry: dummyGeometry,
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        startedAt: testDate,
      );

      mockGeofence.setInside('zone-3', false);

      final alerts = useCase(
        position: userPosition,
        zones: [zoneApproaching],
        previousDistancesKm: {'zone-3': 100.0},
      );

      expect(alerts.length, 1);
      final alert = alerts.first;
      expect(alert.approaching, isTrue);
      expect(alert.message, contains('et se rapproche'));
    });

    test('devrait TRIER les alertes : d\'abord l\'utilisateur à l\'intérieur, puis par distance', () {
      final zoneOutsideFar = Zone(
        id: 'z-far',
        isActive: true,
        type: ZoneType.risk,
        severity: Severity.high,
        disasterType: DisasterType.cyclone,
        geometry: dummyGeometry,
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        startedAt: testDate,
      );

      final zoneInside = Zone(
        id: 'z-inside',
        isActive: true,
        type: ZoneType.risk,
        severity: Severity.high,
        disasterType: DisasterType.flood,
        geometry: dummyGeometry,
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        startedAt: testDate,
      );

      mockGeofence.setInside('z-far', false);
      mockGeofence.setInside('z-inside', true);

      final alerts = useCase(
        position: userPosition,
        zones: [zoneOutsideFar, zoneInside],
      );

      expect(alerts.length, 2);
      expect(alerts[0].zoneId, equals('z-inside'));
      expect(alerts[1].zoneId, equals('z-far'));
    });
  });
}