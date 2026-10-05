import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/shelter_entity.dart';


/// Données saisies pour créer un refuge. Le reste (id, dates, validation,
/// occupation, statut initial « fermé ») est fixé par le système.
class ShelterDraft {
  const ShelterDraft({
    required this.name,
    required this.address,
    required this.location,
    required this.capacityTotal,
    this.resources = const ShelterResources(),
  });

  final String name;
  final String address;
  final GeoPoint location;
  final int capacityTotal;
  final ShelterResources resources;
}
