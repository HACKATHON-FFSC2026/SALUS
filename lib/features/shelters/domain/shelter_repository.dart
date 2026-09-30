import 'package:salus/core/entities/entities.dart';

/// Contrat d'accès aux refuges. Les consommateurs dépendent de cette
/// abstraction; les détails Firestore restent dans la couche data.
abstract class ShelterRepository {
  /// Enregistre [shelter] et renvoie la fiche créée avec son identifiant.
  Future<Shelter> createShelter(Shelter shelter);

  /// Refuges validés visibles sur la carte, alimentés en temps réel.
  Stream<List<Shelter>> watchValidatedShelters();

  /// Tous les refuges pour la liste, quel que soit leur statut de validation.
  Stream<List<Shelter>> watchAllShelters();
}
