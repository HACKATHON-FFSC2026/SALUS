import 'package:salus/features/shelter_manager/domain/entities/shelter_draft.dart';
import 'package:salus/features/shelter_manager/domain/repositories/shelter_manager_repository.dart';
import 'package:salus/features/shelter_manager/domain/shelter_rules.dart';
import 'package:salus/core/entities/shelter_entity.dart';


class WatchIsShelterManager {
  const WatchIsShelterManager(this._repo);
  final ShelterManagerRepository _repo;
  Stream<bool> call(String uid) => _repo.watchIsShelterManager(uid);
}

class WatchManagedShelters {
  const WatchManagedShelters(this._repo);
  final ShelterManagerRepository _repo;
  Stream<List<Shelter>> call(String uid) => _repo.watchManagedShelters(uid);
}

class CreateManagedShelter {
  const CreateManagedShelter(this._repo);
  final ShelterManagerRepository _repo;

  Future<String> call(String uid, ShelterDraft draft) {
    if (draft.name.trim().length < 3) {
      throw ArgumentError('Le nom doit faire 3 caractères minimum');
    }
    if (draft.capacityTotal <= 0) {
      throw ArgumentError('La capacité doit être supérieure à 0');
    }
    return _repo.createShelter(uid, draft);
  }
}

/// Calcule la nouvelle occupation et le statut qui en découle, puis écrit
/// des valeurs absolues (fonctionne hors-ligne, la file Firestore rejoue).
class AdjustOccupancy {
  const AdjustOccupancy(this._repo);
  final ShelterManagerRepository _repo;

  Future<void> call(Shelter shelter, int delta) {
    final next = ShelterRules.clampOccupancy(
      shelter.capacityOccupied + delta,
      shelter.capacityTotal,
    );
    if (next == shelter.capacityOccupied) return Future.value();
    final status = ShelterRules.statusFor(
      // Un décompte réévalue le statut (un « complet » manuel est levé).
      requested: shelter.status == ShelterStatus.closed
          ? ShelterStatus.closed
          : ShelterStatus.open,
      capacity: shelter.capacityTotal,
      occupancy: next,
    );
    return _repo.updateOccupancy(shelter.id, next, status);
  }
}

class SetShelterStatus {
  const SetShelterStatus(this._repo);
  final ShelterManagerRepository _repo;

  Future<void> call(Shelter shelter, ShelterStatus requested) {
    final status = ShelterRules.statusFor(
      requested: requested,
      capacity: shelter.capacityTotal,
      occupancy: shelter.capacityOccupied,
    );
    return _repo.updateStatus(shelter.id, status);
  }
}

class DeclareShelterResources {
  const DeclareShelterResources(this._repo);
  final ShelterManagerRepository _repo;
  Future<void> call(String shelterId, ShelterResources resources) =>
      _repo.updateResources(shelterId, resources);
}
