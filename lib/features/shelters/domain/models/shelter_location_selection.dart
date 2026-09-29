import 'package:cloud_firestore/cloud_firestore.dart';

/// Localisation confirmée pour un refuge : coordonnées (`GeoPoint`, champ
/// `location` de l'Entity Shelter) + adresse lisible facultative.
class ShelterLocationSelection {
  const ShelterLocationSelection({required this.location, this.address});

  final GeoPoint location;
  final String? address;
}
