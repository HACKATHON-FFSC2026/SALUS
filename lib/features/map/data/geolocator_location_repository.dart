import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/domain/location_repository.dart';

/// Délai maximal pour une fixation. Sans lui, `getCurrentPosition` ne rend
/// jamais la main quand aucun signal GPS n'arrive (Android
/// geolocator_android.dart n'applique le timeLimit que si on le passe) :
/// l'écran restait bloqué sur le loading jusqu'au kill de l'OS.
const _fixTimeout = Duration(seconds: 10);

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

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _fixTimeout,
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      throw const LocationFailureException(LocationFailure.timeout);
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
