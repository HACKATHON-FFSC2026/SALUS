import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/shelters/data/shelter_repository.dart';
import 'package:salus/features/shelters/domain/models/shelter_creation_state.dart';
import 'package:salus/features/shelters/presentation/controllers/shelter_creation_controller.dart';

class _FakeShelterRepository implements ShelterRepository {
  _FakeShelterRepository({this.fail = false});

  final bool fail;
  final List<Shelter> created = [];

  @override
  Future<Shelter> createShelter(Shelter shelter) async {
    if (fail) throw Exception('firestore indisponible');
    final saved = shelter.copyWith(id: 'shelter-1');
    created.add(saved);
    return saved;
  }
}

void main() {
  late _FakeShelterRepository repository;

  ProviderContainer makeContainer({String? userId, bool fail = false}) {
    repository = _FakeShelterRepository(fail: fail);
    return ProviderContainer.test(
      overrides: [
        shelterRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue(userId),
      ],
    );
  }

  Future<void> createShelter(ProviderContainer container) {
    return container
        .read(shelterCreationControllerProvider.notifier)
        .createShelter(
          name: '  Lycée Ampefiloha  ',
          address: '  Antananarivo  ',
          location: const GeoPoint(-18.9, 47.5),
          capacityTotal: 120,
          resources: const ShelterResources(water: true),
        );
  }

  test('crée un refuge avec les valeurs par défaut du MVP', () async {
    final container = makeContainer(userId: 'user-1');

    await createShelter(container);

    final state = container.read(shelterCreationControllerProvider);
    expect(state.status, ShelterCreationStatus.success);
    expect(state.shelter?.id, 'shelter-1');

    final saved = repository.created.single;
    expect(saved.name, 'Lycée Ampefiloha');
    expect(saved.address, 'Antananarivo');
    expect(saved.createdBy, 'user-1');
    expect(saved.capacityTotal, 120);
    expect(saved.capacityOccupied, 0);
    expect(saved.status, ShelterStatus.open);
    expect(saved.validationStatus, ValidationStatus.pending);
    expect(saved.unsafeReportsCount, 0);
    expect(saved.photos, isEmpty);
    expect(saved.resources.water, isTrue);
    expect(saved.resources.food, isFalse);
    expect(saved.createdAt, saved.updatedAt);
  });

  test('refuse la création sans utilisateur connecté', () async {
    final container = makeContainer(userId: null);

    await createShelter(container);

    final state = container.read(shelterCreationControllerProvider);
    expect(state.status, ShelterCreationStatus.error);
    expect(state.errorMessage, isNotNull);
    expect(repository.created, isEmpty);
  });

  test('passe en erreur quand la persistance échoue', () async {
    final container = makeContainer(userId: 'user-1', fail: true);

    await createShelter(container);

    final state = container.read(shelterCreationControllerProvider);
    expect(state.status, ShelterCreationStatus.error);
    expect(state.errorMessage, isNotNull);
  });

  test('reset repart d\'un état vierge', () async {
    final container = makeContainer(userId: 'user-1');
    await createShelter(container);

    container.read(shelterCreationControllerProvider.notifier).reset();

    final state = container.read(shelterCreationControllerProvider);
    expect(state.status, ShelterCreationStatus.idle);
    expect(state.shelter, isNull);
    expect(state.errorMessage, isNull);
  });
}
