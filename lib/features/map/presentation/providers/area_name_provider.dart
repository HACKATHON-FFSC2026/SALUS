import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/app/di/app_dependencies.dart';

/// Nom « quartier, ville » d'un point (geocoding inverse Nominatim), mis en
/// cache par coordonnées. Sert à situer une zone sans afficher de lat/long.
final areaNameProvider = FutureProvider.family<String?, LatLng>((ref, point) {
  return ref.watch(geocodingServiceProvider).reverseArea(point);
});
