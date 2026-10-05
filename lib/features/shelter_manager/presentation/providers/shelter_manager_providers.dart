import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/shelter_manager/data/datasources/shelter_manager_remote_datasource.dart';
import 'package:salus/features/shelter_manager/data/repositories/shelter_manager_repository_impl.dart';
import 'package:salus/features/shelter_manager/domain/entities/shelter_draft.dart';
import 'package:salus/features/shelter_manager/domain/repositories/shelter_manager_repository.dart';
import 'package:salus/features/shelter_manager/domain/usecases/shelter_manager_usecases.dart';
import 'package:salus/core/entities/shelter_entity.dart';


// ---- Injection --------------------------------------------------------------

final shelterManagerFirestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final shelterManagerRepositoryProvider = Provider<ShelterManagerRepository>(
  (ref) => ShelterManagerRepositoryImpl(
    ShelterManagerRemoteDataSource(ref.watch(shelterManagerFirestoreProvider)),
  ),
);

// ---- Flux temps réel --------------------------------------------------------

/// true si le compte connecté porte le rôle shelterManager.
/// Utilisable au démarrage : `await ref.read(isShelterManagerProvider.future)`.
final isShelterManagerProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return WatchIsShelterManager(ref.watch(shelterManagerRepositoryProvider))(uid);
});

final managedSheltersProvider = StreamProvider<List<Shelter>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return WatchManagedShelters(ref.watch(shelterManagerRepositoryProvider))(uid);
});

// ---- Actions ----------------------------------------------------------------

final shelterActionsProvider =
    AsyncNotifierProvider<ShelterActionsNotifier, void>(
  ShelterActionsNotifier.new,
);

class ShelterActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ShelterManagerRepository get _repo =>
      ref.read(shelterManagerRepositoryProvider);

  /// Création : état « loading » pour le bouton, retourne l'id ou null.
  Future<String?> createShelter(ShelterDraft draft) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return null;
    state = const AsyncLoading();
    try {
      final id = await CreateManagedShelter(_repo)(uid, draft);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Actions rapides : pas de « loading » (boutons toujours réactifs, l'UI
  /// suit le flux Firestore, y compris hors-ligne). Seule l'erreur remonte.
  Future<void> _quiet(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> adjustOccupancy(Shelter shelter, int delta) =>
      _quiet(() => AdjustOccupancy(_repo)(shelter, delta));

  Future<void> setStatus(Shelter shelter, ShelterStatus status) =>
      _quiet(() => SetShelterStatus(_repo)(shelter, status));

  Future<void> setResources(Shelter shelter, ShelterResources resources) =>
      _quiet(() => DeclareShelterResources(_repo)(shelter.id, resources));
}
