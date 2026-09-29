import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/sources/firestore_client.dart';
import 'package:salus/core/utils/log.dart';

/// Persistance des fiches refuge (collection Firestore `shelters`).
abstract class ShelterRepository {
  /// Enregistre [shelter] et renvoie la fiche telle qu'écrite, identifiant
  /// Firestore compris.
  Future<Shelter> createShelter(Shelter shelter);

  /// Refuges validés visibles publiquement, en temps réel.
  ///
  /// Les refuges `pending` et `rejected` ne quittent jamais la base : le
  /// filtrage se fait dans la requête, une seule fois pour toute la carte.
  Stream<List<Shelter>> watchValidatedShelters();
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

  @override
  Stream<List<Shelter>> watchValidatedShelters() {
    return _firestore
        .collection(collection)
        .where('validationStatus', isEqualTo: ValidationStatus.validated.name)
        .snapshots()
        .map(decodeSnapshot);
  }

  /// Convertit un document Firestore en [Shelter].
  ///
  /// Renvoie `null` quand le document est illisible : une fiche au schéma
  /// incomplet ne doit pas casser l'affichage des autres refuges.
  static Shelter? decodeShelter(String docId, Map<String, dynamic> data) {
    try {
      final id = data['id'];
      return Shelter.fromJson(<String, Object?>{
        ...data,
        'id': id is String && id.isNotEmpty ? id : docId,
      });
    } catch (e, s) {
      Log.error('Refuge $docId illisible, ignoré', e, s);
      return null;
    }
  }

  /// Tous les refuges d'un snapshot, triés par nom pour garder un ordre stable
  /// entre deux mises à jour Firestore.
  static List<Shelter> decodeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => decodeShelter(doc.id, doc.data()))
        .whereType<Shelter>()
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

final shelterRepositoryProvider = Provider<ShelterRepository>(
  (ref) => FirestoreShelterRepository(ref.watch(firestoreProvider)),
);
