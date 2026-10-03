import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/widgets/salus_map_widget.dart';
import 'package:salus/features/risks/domain/repositories/safe_zone.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/shelters/data/shelter_repository.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_marker_pin.dart';

/// Tuile 1x1 en mémoire.
///
/// Les tuiles OSM demandent le réseau: les requêtes échouent en test et
/// laissent des timers en vol, ce qui fait échouer le test au démontage
/// (« A Timer is still pending »). Une image locale supprime la requête.
class _FakeTileProvider extends TileProvider {
  static final _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPng);
}

/// Repository de test : la requête Firestore (filtrage `validationStatus`) est
/// simulée en amont, la carte ne reçoit que des refuges validés.
class _StubShelterRepository implements ShelterRepository {
  _StubShelterRepository({this.shelters = const [], this.fail = false});

  final List<Shelter> shelters;
  final bool fail;

  @override
  Future<Shelter> createShelter(Shelter shelter) async => shelter;

  @override
  Stream<List<Shelter>> watchValidatedShelters() {
    if (fail) {
      return Stream<List<Shelter>>.error(Exception('firestore indisponible'));
    }
    return Stream<List<Shelter>>.value(shelters);
  }

  @override
  Stream<List<Shelter>> watchAllShelters() => watchValidatedShelters();
}

Shelter _shelter({
  String id = 'shelter-1',
  String name = 'Refuge Mahamasina',
  ShelterStatus status = ShelterStatus.open,
  double lat = -18.8792,
  double lon = 47.5079,
}) {
  return Shelter(
    id: id,
    name: name,
    location: GeoPoint(lat, lon),
    address: 'Mahamasina, Antananarivo',
    capacityTotal: 50,
    capacityOccupied: 12,
    status: status,
    resources: const ShelterResources(water: true, food: true),
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
}

Future<void> _pumpMap(WidgetTester tester, ShelterRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shelterRepositoryProvider.overrideWithValue(repository),
        // La carte watch aussi les zones à risque (API GDACS) et les zones sûres
        // (API altitude). Les deux passent par `dio`, qui laisse des timers en
        // vol et fait échouer le test au démontage. `riskZonesProvider` pose en
        // plus un `Timer` de 15 min pour son auto-refresh.
        riskZonesProvider.overrideWith((ref) async => const <Zone>[]),
        activeRiskZonesProvider.overrideWith(
          (ref) => Stream.value(const <Zone>[]),
        ),
        safeZoneRepositoryProvider.overrideWithValue(_StubSafeZoneRepository()),
      ],
      child: _mapApp(),
    ),
  );
  // Laisse le flux des refuges livrer son premier état.
  await tester.pump();
  await tester.pump();
}

class _StubSafeZoneRepository implements SafeZoneRepository {
  @override
  Future<List<Zone>> getSafeZonesAround(GeoPoint center) async => const [];
}

Widget _mapApp() =>
    MaterialApp(home: SalusMapWidget(tileProvider: _FakeTileProvider()));

void main() {
  testWidgets('affiche un marker par refuge validé', (tester) async {
    await _pumpMap(
      tester,
      _StubShelterRepository(
        shelters: [
          _shelter(),
          _shelter(
            id: 'shelter-2',
            name: 'Refuge Ampefiloha',
            status: ShelterStatus.almostFull,
            // Coordonnées distinctes: deux refuges au même point seraient
            // fusionnés par le clustering et aucun marker n'existerait.
            lat: -18.9100,
            lon: 47.5500,
          ),
        ],
      ),
    );

    expect(find.byType(ShelterMarkerPin), findsNWidgets(2));
    expect(find.text('Aucun refuge disponible à proximité.'), findsNothing);
    expect(find.text('Impossible de charger les refuges.'), findsNothing);
  });

  testWidgets('affiche l\'état vide quand aucun refuge n\'est validé', (
    tester,
  ) async {
    await _pumpMap(tester, _StubShelterRepository());

    expect(find.byType(ShelterMarkerPin), findsNothing);
    expect(find.text('Aucun refuge disponible à proximité.'), findsOneWidget);
  });

  testWidgets('affiche l\'erreur Firestore avec une action Réessayer', (
    tester,
  ) async {
    await _pumpMap(tester, _StubShelterRepository(fail: true));

    expect(find.text('Impossible de charger les refuges.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.byType(ShelterMarkerPin), findsNothing);
  });

  testWidgets('un tap sur un marker ouvre la fiche du refuge', (tester) async {
    await _pumpMap(tester, _StubShelterRepository(shelters: [_shelter()]));

    await tester.tap(find.byType(ShelterMarkerPin));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Refuge Mahamasina'), findsOneWidget);
    expect(find.text('38 places disponibles'), findsOneWidget);
    expect(find.text('Voir le refuge'), findsOneWidget);
  });
}
