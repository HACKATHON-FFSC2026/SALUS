import 'package:salus/features/shelter_manager/domain/entities/shelter_draft.dart';
import 'package:salus/core/entities/shelter_entity.dart';


/// Port du domaine. Implémentation dans features/shelter_manager/data.
abstract class ShelterManagerRepository {
  /// true si users/{uid} porte le rôle shelterManager et est actif.
  Stream<bool> watchIsShelterManager(String uid);

  /// Refuges dont `managedBy` == uid, en temps réel.
  Stream<List<Shelter>> watchManagedShelters(String uid);

  Future<String> createShelter(String uid, ShelterDraft draft);

  Future<void> updateOccupancy(
    String shelterId,
    int occupancy,
    ShelterStatus status,
  );

  Future<void> updateStatus(String shelterId, ShelterStatus status);

  Future<void> updateResources(String shelterId, ShelterResources resources);
}
