import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/reports/presentation/widgets/road_incident_location_picker.dart';

class _FakeTileProvider extends TileProvider {
  static final _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPng);
}

void main() {
  testWidgets('allows selecting a map point and returns its coordinates', (
    tester,
  ) async {
    const initialLocation = GeoPoint(latitude: -18.88, longitude: 47.51);
    GeoPoint? selectedLocation;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selectedLocation = await showRoadIncidentLocationPicker(
                  context,
                  initialLocation: initialLocation,
                  tileProvider: _FakeTileProvider(),
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    expect(find.text('Aucun point sélectionné'), findsOneWidget);
    final confirmButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Utiliser ce point'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(confirmButton.onPressed, isNull);

    final mapRect = tester.getRect(find.byType(FlutterMap));
    await tester.tapAt(Offset(mapRect.left + 60, mapRect.top + 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Point sélectionné'), findsOneWidget);
    await tester.tap(find.text('Utiliser ce point'));
    await tester.pumpAndSettle();

    expect(selectedLocation, isNotNull);
    expect(selectedLocation, isNot(initialLocation));
  });

  testWidgets('cancelling the picker does not return a point', (tester) async {
    const initialLocation = GeoPoint(latitude: -18.88, longitude: 47.51);
    GeoPoint? selectedLocation = initialLocation;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selectedLocation = await showRoadIncidentLocationPicker(
                  context,
                  initialLocation: initialLocation,
                  tileProvider: _FakeTileProvider(),
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Annuler'));
    await tester.pumpAndSettle();

    expect(selectedLocation, isNull);
  });
}
