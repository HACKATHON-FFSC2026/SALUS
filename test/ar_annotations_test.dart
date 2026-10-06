import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/ar/presentation/models/salus_ar_annotation.dart';
import 'package:salus/features/ar/presentation/widgets/ar_annotation_card.dart';

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
    geometry: const [GeoPoint(-18.91, 47.51), GeoPoint(-18.92, 47.52)],
    isActive: true,
    startedAt: DateTime(2026),
  );

  test('ne garde que les refuges utilisables (validé, ouvert, places)', () {
    final annotations = buildArAnnotations(
      [
        shelter(id: 'a'),
        shelter(id: 'b', status: ShelterStatus.full),
        shelter(id: 'c', status: ShelterStatus.closed),
        shelter(id: 'd', validation: ValidationStatus.pending),
        shelter(id: 'e', total: 10, occupied: 10),
      ],
      [],
      [],
    );

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
      {'zone-z1-risk': ArPoiType.riskZone, 'zone-z2-safe': ArPoiType.safeZone},
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

  testWidgets('relie la pastille au point projeté', (tester) async {
    const pulse = AlwaysStoppedAnimation<double>(0);
    final annotation = SalusArAnnotation(
      poi: ArPoi(
        uid: 'shelter-tap',
        title: 'Refuge tap',
        icon: Icons.night_shelter,
        color: Colors.green,
        shelter: shelter(id: 'tap'),
        position: Position(
          latitude: -18.9,
          longitude: 47.5,
          timestamp: DateTime(2026),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
        type: ArPoiType.shelter,
      ),
    )..arPosition = const Offset(0, 200);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ArAnnotationCard(annotation: annotation, pulse: pulse),
        ),
      ),
    );

    final annotationFinder = find.byType(ArAnnotationCard);
    final cardFinder = find.descendant(
      of: annotationFinder,
      matching: find.byType(InkWell),
    );
    final stemFinder = find.descendant(
      of: annotationFinder,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox &&
            widget.color == Colors.white.withValues(alpha: 0.85),
      ),
    );
    final pointFinder = find.descendant(
      of: annotationFinder,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 10 &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    );

    expect(
      tester.getRect(stemFinder).top,
      closeTo(tester.getRect(cardFinder).bottom, 0.1),
    );
    expect(
      tester.getRect(stemFinder).bottom,
      closeTo(tester.getRect(pointFinder).center.dy, 0.1),
    );
    expect(
      tester
          .getRect(annotationFinder)
          .contains(tester.getRect(cardFinder).topLeft),
      isTrue,
    );

    await tester.tapAt(tester.getRect(stemFinder).center);
    await tester.pumpAndSettle();
    expect(find.text('Ressources disponibles'), findsNothing);

    await tester.tapAt(tester.getRect(cardFinder).center);
    await tester.pumpAndSettle();
    expect(find.text('Ressources disponibles'), findsOneWidget);
    Navigator.of(tester.element(annotationFinder)).pop();
    await tester.pumpAndSettle();

    annotation.arPosition = const Offset(0, -120);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ArAnnotationCard(annotation: annotation, pulse: pulse),
        ),
      ),
    );

    expect(
      tester.getRect(stemFinder).top,
      closeTo(tester.getRect(pointFinder).center.dy, 0.1),
    );
    expect(
      tester.getRect(stemFinder).bottom,
      closeTo(tester.getRect(cardFinder).top, 0.1),
    );
    final cardRect = tester.getRect(cardFinder);
    final annotationRect = tester.getRect(annotationFinder);
    expect(annotationRect.right, greaterThanOrEqualTo(cardRect.right));
    expect(annotationRect.bottom, greaterThanOrEqualTo(cardRect.bottom));
  });
}
