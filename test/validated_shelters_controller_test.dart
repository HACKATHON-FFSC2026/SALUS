import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/shelters/data/shelter_repository.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';

class _FakeShelterRepository implements ShelterRepository {
  final _controller = StreamController<List<Shelter>>();
  int watchCalls = 0;

  @override
  Future<Shelter> createShelter(Shelter shelter) async => shelter;

  @override
  Stream<List<Shelter>> watchValidatedShelters() {
    watchCalls++;
    return _controller.stream;
  }

  @override
  Stream<List<Shelter>> watchAllShelters() => _controller.stream;

  void emit(List<Shelter> shelters) => _controller.add(shelters);
  void fail(Object error) => _controller.addError(error);
  Future<void> close() => _controller.close();
}

Shelter _shelter({String id = 'shelter-1', String name = 'Refuge Mahamasina'}) {
  return Shelter(
    id: id,
    name: name,
    location: const GeoPoint(-18.8792, 47.5079),
    address: 'Mahamasina, Antananarivo',
    capacityTotal: 50,
    capacityOccupied: 12,
    status: ShelterStatus.open,
    resources: const ShelterResources(water: true),
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
}

void main() {
  test('expose les refuges émis par le repository', () async {
    final repository = _FakeShelterRepository();
    final container = ProviderContainer.test(
      overrides: [shelterRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(validatedSheltersProvider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(repository.close);

    // Le flux Firestore est branché dès la première lecture.
    expect(repository.watchCalls, 1);
    expect(container.read(validatedSheltersProvider).isLoading, isTrue);

    repository.emit([_shelter()]);
    await pumpEventQueue();

    final state = container.read(validatedSheltersProvider);
    expect(state.hasError, isFalse);
    expect(state.value, hasLength(1));
    expect(state.value!.single.name, 'Refuge Mahamasina');
    expect(state.value!.single.location.latitude, -18.8792);
  });

  test('expose une erreur quand Firestore échoue', () async {
    final repository = _FakeShelterRepository();
    final container = ProviderContainer.test(
      overrides: [shelterRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(validatedSheltersProvider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(repository.close);

    repository.fail(Exception('firestore indisponible'));
    await pumpEventQueue();

    final state = container.read(validatedSheltersProvider);
    expect(state.hasError, isTrue);
    expect(state.value, isNull);
  });
}
