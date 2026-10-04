import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/risks/domain/services/zone_geofence_service.dart';
import 'package:salus/features/shelters/domain/usecases/find_shelters_in_risk_zones.dart';

class _GeofenceFake implements ZoneGeofenceService {
  @override
  bool isUserInZone(GeoPoint userPosition, Zone zone) =>
      zone.id == 'active-risk' && userPosition.latitude < -18.85;
}

void main() {
  final useCase = FindSheltersInRiskZones(_GeofenceFake());

  Shelter shelter(String id) => Shelter(
    id: id,
    name: 'Refuge $id',
    location: GeoPoint(id == 'unsafe' ? -18.9 : -18.8, 47.5),
    address: 'Adresse',
    capacityTotal: 20,
    status: ShelterStatus.open,
    resources: const ShelterResources(),
    createdBy: 'admin',
    validationStatus: ValidationStatus.validated,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Zone zone(String id, {ZoneType type = ZoneType.risk, bool active = true}) =>
      Zone(
        id: id,
        type: type,
        geometry: const [
          GeoPoint(-18.8, 47.5),
          GeoPoint(-18.8, 47.6),
          GeoPoint(-18.9, 47.5),
        ],
        origin: ZoneOrigin.automatic,
        source: 'GDACS',
        isActive: active,
        startedAt: DateTime(2026),
      );

  test('returns shelters within known active risk zones', () {
    final unsafe = shelter('unsafe');
    final safe = shelter('safe');

    expect(useCase(shelters: [unsafe, safe], zones: [zone('active-risk')]), {
      'unsafe',
    });
  });

  test('ignores inactive zones, safe zones, and invalid polygons', () {
    expect(
      useCase(
        shelters: [shelter('shelter')],
        zones: [
          zone('active-risk', active: false),
          zone('active-risk', type: ZoneType.safe),
          zone('active-risk').copyWith(geometry: const [GeoPoint(0, 0)]),
        ],
      ),
      isEmpty,
    );
  });
}
