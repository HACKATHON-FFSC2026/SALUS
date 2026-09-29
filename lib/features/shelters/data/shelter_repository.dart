import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/sources/firestore_client.dart';

/// Persistance des fiches refuge (collection Firestore `shelters`).
abstract class ShelterRepository {
  /// Enregistre [shelter] et renvoie la fiche telle qu'écrite, identifiant
  /// Firestore compris.
  Future<Shelter> createShelter(Shelter shelter);
}

class FirestoreShelterRepository implements ShelterRepository {
  FirestoreShelterRepository(this._firestore);

  static const collection = 'shelters';

  final FirebaseFirestore _firestore;

  @override
  Future<Shelter> createShelter(Shelter shelter) async {
    // ponytail: l'id est généré côté client pour que le champ `id` du document
    // reste égal à l'id du document Firestore. Passer à `add()` si les règles
    // de sécurité doivent générer l'id côté serveur.
    final doc = _firestore
        .collection(collection)
        .doc(shelter.id.isEmpty ? null : shelter.id);
    final created = shelter.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }
}

final shelterRepositoryProvider = Provider<ShelterRepository>(
  (ref) => FirestoreShelterRepository(ref.watch(firestoreProvider)),
);
