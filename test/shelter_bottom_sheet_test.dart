import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_bottom_sheet.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';

Shelter _shelter({
  ShelterStatus status = ShelterStatus.open,
  ShelterResources resources = const ShelterResources(water: true, food: true),
}) {
  return Shelter(
    id: 'shelter-1',
    name: 'Refuge Mahamasina',
    location: const GeoPoint(-18.8792, 47.5079),
    address: 'Mahamasina, Antananarivo',
    capacityTotal: 50,
    capacityOccupied: 12,
    status: status,
    resources: resources,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1, 8, 30),
    updatedAt: DateTime(2026, 1, 2, 9, 45),
  );
}

Future<void> _pumpSheet(WidgetTester tester, Shelter shelter) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ShelterBottomSheet(shelter: shelter, onSeeDetails: () {}),
      ),
    ),
  );
}

void main() {
  test('chaque statut a son libellé', () {
    expect(ShelterStatus.open.label, 'Ouvert');
    expect(ShelterStatus.almostFull.label, 'Presque complet');
    expect(ShelterStatus.full.label, 'Complet');
    expect(ShelterStatus.closed.label, 'Fermé');
  });

  testWidgets('affiche nom, adresse, capacité, statut et ressources activées', (
    tester,
  ) async {
    await _pumpSheet(tester, _shelter());

    expect(find.text('Refuge Mahamasina'), findsOneWidget);
    expect(find.text('Mahamasina, Antananarivo'), findsOneWidget);
    expect(find.text('38 places disponibles'), findsOneWidget);
    expect(find.text('Ouvert'), findsOneWidget);
    expect(find.text('Eau'), findsOneWidget);
    expect(find.text('Nourriture'), findsOneWidget);
    expect(find.text('Voir le refuge'), findsOneWidget);

    // Les ressources désactivées ne sont pas affichées.
    expect(find.text('Électricité'), findsNothing);
    expect(find.text('Kit médical'), findsNothing);
  });

  testWidgets('affiche le statut presque complet', (tester) async {
    await _pumpSheet(tester, _shelter(status: ShelterStatus.almostFull));

    expect(find.text('Presque complet'), findsOneWidget);
    expect(find.text('Ouvert'), findsNothing);
  });

  testWidgets('affiche le statut complet', (tester) async {
    await _pumpSheet(tester, _shelter(status: ShelterStatus.full));

    expect(find.text('Complet'), findsOneWidget);
  });

  testWidgets('affiche le statut fermé', (tester) async {
    await _pumpSheet(tester, _shelter(status: ShelterStatus.closed));

    expect(find.text('Fermé'), findsOneWidget);
  });

  testWidgets('signale l\'absence de ressource', (tester) async {
    await _pumpSheet(tester, _shelter(resources: const ShelterResources()));

    expect(find.text('Aucune ressource renseignée.'), findsOneWidget);
    expect(find.text('Eau'), findsNothing);
  });

  testWidgets('le bouton « Voir le refuge » ouvre la fiche complète', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showShelterBottomSheet(context, _shelter()),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Voir le refuge'), findsOneWidget);

    await tester.tap(find.text('Voir le refuge'));
    await tester.pumpAndSettle();

    expect(find.text('Localisation'), findsOneWidget);
    expect(find.text('-18.87920, 47.50790'), findsOneWidget);
    expect(find.text('01/01/2026 08:30'), findsOneWidget);
    expect(find.text('02/01/2026 09:45'), findsOneWidget);
    expect(find.text('12 / 50 personnes'), findsOneWidget);
  });
}
