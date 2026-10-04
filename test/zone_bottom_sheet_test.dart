import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/presentation/providers/area_name_provider.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';
import 'package:salus/features/map/presentation/widgets/zone_bottom_sheet.dart';

Zone _zone() => Zone(
  id: 'zone-1',
  type: ZoneType.risk,
  disasterType: DisasterType.flood,
  severity: Severity.critical,
  geometry: const [
    firestore.GeoPoint(-18.88, 47.5),
    firestore.GeoPoint(-18.87, 47.51),
  ],
  description: 'Crue de la plaine.',
  origin: ZoneOrigin.manual,
  source: 'test',
  isActive: true,
  startedAt: DateTime(2026, 1, 1),
);

class _FakeLocation extends LocationNotifier {
  _FakeLocation(this._position);
  final GeoPoint? _position;

  @override
  LocationState build() => LocationState(position: _position);
}

Future<void> _pumpZone(
  WidgetTester tester,
  Zone zone, {
  GeoPoint? userPosition,
  String? areaName = 'Mahamasina, Antananarivo',
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        locationProvider.overrideWith(() => _FakeLocation(userPosition)),
        areaNameProvider.overrideWith((ref, _) async => areaName),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Column(children: [Expanded(child: ZoneBottomSheet(zone: zone))]),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('une zone à risque affiche type, gravité et fiche', (
    tester,
  ) async {
    await _pumpZone(tester, _zone());

    expect(find.text('Zone Inondation'), findsOneWidget);
    expect(find.text('Gravité critique'), findsOneWidget);
    expect(find.text('Critique'), findsOneWidget);
    expect(find.text('Crue de la plaine.'), findsOneWidget);
  });

  testWidgets('affiche le quartier et la ville de la zone', (tester) async {
    await _pumpZone(tester, _zone());
    await tester.pump();
    expect(find.textContaining('Mahamasina, Antananarivo'), findsOneWidget);
  });

  testWidgets('lieu inconnu quand le geocoding ne renvoie rien', (tester) async {
    await _pumpZone(tester, _zone(), areaName: null);
    await tester.pump();
    expect(find.textContaining('Lieu inconnu'), findsOneWidget);
  });

  testWidgets('la position est décrite en distance et direction', (tester) async {
    // Utilisateur à l'est du centroïde: « à 2.1 km à l'ouest de vous ».
    await _pumpZone(
      tester,
      _zone(),
      userPosition: const GeoPoint(latitude: -18.875, longitude: 47.525),
    );

    expect(find.textContaining('de vous'), findsOneWidget);
    expect(find.textContaining('2.1 km'), findsOneWidget);
    // Aucune latitude/longitude brute à l'écran.
    expect(find.textContaining('Lat.'), findsNothing);
    expect(find.textContaining('-18.8'), findsNothing);
  });

  testWidgets('sans position GPS, la position est signalée indisponible', (
    tester,
  ) async {
    await _pumpZone(tester, _zone());
    expect(find.textContaining('Localisation indisponible'), findsOneWidget);
  });

  testWidgets('une zone sûre précise sa nature (élévation)', (tester) async {
    await _pumpZone(
      tester,
      Zone(
        id: 'safe-1',
        type: ZoneType.safe,
        geometry: const [firestore.GeoPoint(-18.88, 47.5)],
        description: "Point haut : ~1250 m d'altitude.",
        origin: ZoneOrigin.automatic,
        source: 'Open-Meteo Elevation (heuristique)',
        isActive: true,
        startedAt: DateTime(2026, 1, 1),
      ),
    );

    expect(find.text('Zone sûre'), findsOneWidget);
    expect(
      find.textContaining('Élévation (terrain surélevé)'),
      findsOneWidget,
    );
  });

  testWidgets('le message de description vide s\'affiche', (tester) async {
    await _pumpZone(
      tester,
      Zone(
        id: 'zone-2',
        type: ZoneType.risk,
        disasterType: DisasterType.flood,
        geometry: const [firestore.GeoPoint(-18.88, 47.5)],
        origin: ZoneOrigin.manual,
        source: 'test',
        isActive: true,
        startedAt: DateTime(2026, 1, 1),
      ),
    );

    expect(
      find.text('Aucune description fournie pour cette zone.'),
      findsOneWidget,
    );
  });
}
