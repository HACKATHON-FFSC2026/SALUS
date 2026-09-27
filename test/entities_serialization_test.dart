import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';

void main() {
  test('entities survive a json round-trip', () {
    // ponytail: Timestamp.toDate() renvoie du local — le test utilise du local.
    final t1 = DateTime(2026, 1, 1);
    final t2 = DateTime(2026, 1, 2);
    final user = User(
      id: 'u1',
      displayName: 'Aina',
      email: 'a@example.com',
      authProvider: AuthProvider.google,
      roles: const [UserRole.citizen],
      safetyStatusUpdatedAt: t1,
      lastActiveAt: t2,
      createdAt: t1,
    );
    expect(User.fromJson(user.toJson()), user);

    final shelter = Shelter(
      id: 's1',
      name: 'Abri',
      location: const GeoPoint(-18.9, 47.5),
      address: 'Antananarivo',
      capacityTotal: 100,
      status: ShelterStatus.open,
      resources: const ShelterResources(water: true),
      createdBy: 'u1',
      createdAt: t1,
      updatedAt: t2,
    );
    final shelterJson = shelter.toJson();
    expect(shelterJson['location'], isA<GeoPoint>());
    expect(shelterJson['createdAt'], isA<Timestamp>());
    expect(Shelter.fromJson(shelterJson), shelter);

    final zone = Zone(
      id: 'z1',
      type: ZoneType.risk,
      geometry: const [GeoPoint(-18.9, 47.5), GeoPoint(-19.0, 47.6)],
      origin: ZoneOrigin.automatic,
      source: 'GDACS',
      startedAt: t1,
    );
    expect(Zone.fromJson(zone.toJson()), zone);
  });
}
