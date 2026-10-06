import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';
import 'package:salus/features/risks/domain/services/zone_geofence_service.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/shelters/domain/usecases/find_shelters_in_risk_zones.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';
import 'package:salus/features/shelters/presentation/pages/shelters_page.dart';

class _TestLocationNotifier extends LocationNotifier {
  @override
  LocationState build() => const LocationState(
    status: LocationStatus.success,
    position: GeoPoint(latitude: -18.8792, longitude: 47.5079),
  );

  @override
  Future<void> refresh() async {}
}

class _GeofenceFake implements ZoneGeofenceService {
  @override
  bool isUserInZone(firestore.GeoPoint userPosition, Zone zone) => false;
}

void main() {
  testWidgets('suspends recommendations until both risk sources load', (
    tester,
  ) async {
    final shelter = Shelter(
      id: 'shelter-1',
      name: 'Refuge central',
      location: const firestore.GeoPoint(-18.8792, 47.5079),
      address: 'Centre-ville',
      capacityTotal: 20,
      status: ShelterStatus.open,
      resources: const ShelterResources(),
      createdBy: 'admin',
      validationStatus: ValidationStatus.validated,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSheltersProvider.overrideWith((ref) => Stream.value([shelter])),
          locationProvider.overrideWith(_TestLocationNotifier.new),
          riskZonesProvider.overrideWith((ref) async => const <Zone>[]),
          activeRiskZonesProvider.overrideWith(
            (ref) => const Stream<List<Zone>>.empty(),
          ),
          findSheltersInRiskZonesProvider.overrideWithValue(
            FindSheltersInRiskZones(_GeofenceFake()),
          ),
        ],
        child: const MaterialApp(home: SheltersPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Vérification des zones de risque en cours. La recommandation est '
        'suspendue jusqu’au chargement de toutes les sources.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'La recommandation attend le chargement de toutes les sources de zones de risque.',
      ),
      findsOneWidget,
    );
  });
}
