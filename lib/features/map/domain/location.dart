/// Point géographique du domaine, sans aucun type de plugin.
///
/// Un `Position` geolocator ici rendrait l'état de localisation
/// untestable hors plateforme et couplerait une règle métier au plugin.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// Raison métier pour laquelle une position n'a pas pu être obtenue.
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationFailureException implements Exception {
  const LocationFailureException(this.failure);

  final LocationFailure failure;

  @override
  String toString() => 'LocationFailureException($failure)';
}
