import 'package:geolocator/geolocator.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/domain/location_repository.dart';

/// Adaptateur Geolocator du port [LocationRepository]. Seul fichier du
/// feature `map` autorisé à importer le plugin.
class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository();

  @override
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailureException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailureException(
        LocationFailure.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailureException(LocationFailure.permissionDenied);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
