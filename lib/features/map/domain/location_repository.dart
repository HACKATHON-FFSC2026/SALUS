import 'package:salus/features/map/domain/location.dart';

/// Port du domaine. La présentation ne dépend que de ce contrat, jamais de
/// Geolocator — implémentation dans features/map/data.
abstract class LocationRepository {
  /// Position courante, ou [LocationFailureException] si le service GPS est
  /// coupé ou la permission refusée.
  Future<GeoPoint> currentPosition();

  /// Réglages système de l'application (permission bloquée définitivement).
  Future<void> openAppSettings();

  /// Réglage GPS de l'appareil.
  Future<void> openLocationSettings();
}
