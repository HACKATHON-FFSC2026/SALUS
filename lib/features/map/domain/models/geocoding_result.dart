import 'package:latlong2/latlong.dart';

/// Résultat d'une recherche de lieu (geocoding direct).
class GeocodingResult {
  const GeocodingResult({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  /// Adresse lisible, ex. « Mahamasina, Antananarivo, Madagascar ».
  final String label;
  final double latitude;
  final double longitude;

  LatLng get point => LatLng(latitude, longitude);

  /// Construit un résultat depuis une entrée Nominatim (`lat`/`lon` arrivent
  /// sous forme de chaînes). Renvoie `null` si l'entrée est inexploitable.
  static GeocodingResult? fromSearchJson(Map<String, dynamic> json) {
    final label = json['display_name'];
    final latitude = double.tryParse('${json['lat']}');
    final longitude = double.tryParse('${json['lon']}');

    if (label is! String ||
        label.isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    return GeocodingResult(
      label: label,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
