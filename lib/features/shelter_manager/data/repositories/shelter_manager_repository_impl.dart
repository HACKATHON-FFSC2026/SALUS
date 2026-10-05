import 'package:salus/features/shelter_manager/data/datasources/shelter_manager_remote_datasource.dart';
import 'package:salus/features/shelter_manager/domain/entities/shelter_draft.dart';
import 'package:salus/features/shelter_manager/domain/repositories/shelter_manager_repository.dart';
import 'package:salus/core/entities/shelter_entity.dart';

class ShelterManagerRepositoryImpl implements ShelterManagerRepository {
  ShelterManagerRepositoryImpl(this._remote);
  final ShelterManagerRemoteDataSource _remote;

  @override
  Stream<bool> watchIsShelterManager(String uid) =>
      _remote.watchIsShelterManager(uid);

  @override
  Stream<List<Shelter>> watchManagedShelters(String uid) =>
      _remote.watchManagedShelters(uid);

  @override
  Future<String> createShelter(String uid, ShelterDraft draft) =>
      _remote.createShelter(uid, draft);

  @override
  Future<void> updateOccupancy(
    String shelterId,
    int occupancy,
    ShelterStatus status,
  ) =>
      _remote.updateOccupancy(shelterId, occupancy, status);

  @override
  Future<void> updateStatus(String shelterId, ShelterStatus status) =>
      _remote.updateStatus(shelterId, status);

  @override
  Future<void> updateResources(String shelterId, ShelterResources resources) =>
      _remote.updateResources(shelterId, resources);
}
