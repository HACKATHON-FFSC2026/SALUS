import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/shelter_manager/domain/entities/shelter_draft.dart';
import 'package:salus/core/entities/shelter_entity.dart';

class ShelterManagerRemoteDataSource {
  ShelterManagerRemoteDataSource(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _shelters =>
      _db.collection('shelters');

  /// Rôle posé manuellement par un admin dans users/{uid}.roles.
  Stream<bool> watchIsShelterManager(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return false;
      final roles = (data['roles'] as List? ?? const []).map((e) => '$e');
      return roles.contains('shelterManager') && data['isActive'] != false;
    });
  }

  Stream<List<Shelter>> watchManagedShelters(String uid) {
    return _shelters.where('managedBy', isEqualTo: uid).snapshots().map((q) {
      final shelters = <Shelter>[];
      for (final doc in q.docs) {
        try {
          shelters.add(Shelter.fromJson(_normalize(doc.id, doc.data())));
        } catch (e) {
          // Un document mal formé ne doit pas casser toute la liste.
          Log.warning('Refuge ${doc.id} illisible: $e');
        }
      }
      shelters.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return shelters;
    });
  }

  Future<String> createShelter(String uid, ShelterDraft d) async {
    final ref = _shelters.doc();
    await ref.set({
      'name': d.name.trim(),
      'location': d.location,
      'address': d.address.trim(),
      'capacityTotal': d.capacityTotal,
      'capacityOccupied': 0,
      'status': ShelterStatus.closed.name,
      'resources': d.resources.toJson(),
      'photos': <String>[],
      'createdBy': uid,
      'managedBy': uid,
      'organizationId': null,
      // Même circuit que le portail : un admin valide ensuite le refuge.
      'validationStatus': ValidationStatus.pending.name,
      'validatedBy': null,
      'unsafeReportsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateOccupancy(
    String id,
    int occupancy,
    ShelterStatus status,
  ) =>
      _shelters.doc(id).update({
        'capacityOccupied': occupancy,
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateStatus(String id, ShelterStatus status) =>
      _shelters.doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateResources(String id, ShelterResources resources) =>
      _shelters.doc(id).update({
        'resources': resources.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Complète les champs absents ou en attente (serverTimestamp = null côté
  /// client tant que l'écriture n'est pas confirmée).
  Map<String, dynamic> _normalize(String id, Map<String, dynamic> data) {
    final d = {...data, 'id': id};
    d['resources'] ??= <String, dynamic>{};
    d['status'] ??= ShelterStatus.closed.name;
    d['capacityOccupied'] ??= 0;
    d['createdBy'] ??= d['managedBy'];
    d['createdAt'] ??= Timestamp.now();
    d['updatedAt'] ??= Timestamp.now();
    return d;
  }
}
