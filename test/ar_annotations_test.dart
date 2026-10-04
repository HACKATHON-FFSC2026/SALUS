import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/ar/presentation/models/salus_ar_annotation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Shelter shelter({
    required String id,
    ShelterStatus status = ShelterStatus.open,
    ValidationStatus validation = ValidationStatus.validated,
    int total = 10,
    int occupied = 2,
  }) => Shelter(
    id: id,
    name: 'Refuge $id',
    location: const GeoPoint(-18.9, 47.5),
    address: 'Antananarivo',
    capacityTotal: total,
    capacityOccupied: occupied,
    status: status,
    resources: const ShelterResources(
      water: false,
      food: false,
      electricity: false,
      medicalKit: false,
    ),
    createdBy: 'test',
    validationStatus: validation,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Zone zone({required String id, ZoneType type = ZoneType.risk}) => Zone(
    id: id,
    type: type,
    origin: ZoneOrigin.manual,
    source: 'test',
    geometry: const [
      GeoPoint(-18.91, 47.51),
      GeoPoint(-18.92, 47.52),
    ],
    isActive: true,
    startedAt: DateTime(2026),
  );

  test('ne garde que les refuges utilisables (validé, ouvert, places)', () {
    final annotations = buildArAnnotations([
      shelter(id: 'a'),
      shelter(id: 'b', status: ShelterStatus.full),
      shelter(id: 'c', status: ShelterStatus.closed),
      shelter(id: 'd', validation: ValidationStatus.pending),
      shelter(id: 'e', total: 10, occupied: 10),
    ], [], []);

    expect(annotations.map((an) => an.poi.uid), ['shelter-a']);
  });

  test('les zones sont incluses via leur centroïde, geometry vide exclu', () {
    final annotations = buildArAnnotations(
      [],
      [zone(id: 'z1'), zone(id: 'z2', type: ZoneType.safe)],
      [
        Zone(
          id: 'z3',
          type: ZoneType.safe,
          origin: ZoneOrigin.manual,
          source: 't',
          isActive: true,
          startedAt: DateTime(2026),
        ),
      ],
    );
    expect(annotations, hasLength(2));
    expect(
      {for (final an in annotations) an.poi.uid: an.poi.type},
      {
        'zone-z1-risk': ArPoiType.riskZone,
        'zone-z2-safe': ArPoiType.safeZone,
      },
    );
  });

  test('les refuges portent le type shelter', () {
    final annotations = buildArAnnotations([shelter(id: 'a')], [], []);
    expect(annotations.single.poi.type, ArPoiType.shelter);
  });

  test('arDistanceLabel', () {
    expect(arDistanceLabel(940), '940 m');
    expect(arDistanceLabel(1523.4), '1.5 km');
  });
}
