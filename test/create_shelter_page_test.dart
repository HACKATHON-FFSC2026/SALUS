import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/shelters/data/shelter_repository.dart';
import 'package:salus/features/shelters/pages/create_shelter_page.dart';
import 'package:salus/features/shelters/presentation/controllers/shelter_creation_controller.dart';

class _FakeShelterRepository implements ShelterRepository {
  @override
  Future<Shelter> createShelter(Shelter shelter) async => shelter;

  // Non utilisé par [CreateShelterPage] : sert uniquement à satisfaire
  // l'interface [ShelterRepository].
  @override
  Stream<List<Shelter>> watchValidatedShelters() =>
      const Stream<List<Shelter>>.empty();

  @override
  Stream<List<Shelter>> watchAllShelters() =>
      const Stream<List<Shelter>>.empty();
}

void main() {
  testWidgets('la localisation est obligatoire pour créer un refuge', (
    tester,
  ) async {
    // Viewport haut : la ListView ne construit que les enfants visibles.
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelterRepositoryProvider.overrideWithValue(_FakeShelterRepository()),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
        child: const MaterialApp(home: CreateShelterPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Aucune localisation sélectionnée.'), findsOneWidget);
    expect(find.text('Sélectionner'), findsOneWidget);

    await tester.ensureVisible(find.text('Créer le refuge'));
    await tester.pump();
    await tester.tap(find.text('Créer le refuge'));
    await tester.pump();

    expect(
      find.text('Veuillez sélectionner la localisation du refuge.'),
      findsOneWidget,
    );
    expect(find.text('Le nom du refuge est obligatoire.'), findsOneWidget);
    expect(find.text('L\'adresse est obligatoire.'), findsOneWidget);
  });
}
