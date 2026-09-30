import 'dart:math' as math;

/// Point géographique du domaine, sans aucun type de plugin.
///
/// Un `Position` geolocator ici rendrait l'état de localisation
/// untestable hors plateforme et couplerait une règle métier au plugin.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// Distance en kilomètres jusqu'à [other], calculée à vol d'oiseau.
  double distanceTo(GeoPoint other) {
    const earthRadiusKm = 6371.0;
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final deltaLat = lat2 - lat1;
    final deltaLon = (other.longitude - longitude) * math.pi / 180;
    final haversine =
        math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

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
