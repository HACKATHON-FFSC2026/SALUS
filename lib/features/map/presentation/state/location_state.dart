import 'package:salus/features/map/domain/location.dart';

enum LocationStatus {
  initial,
  loading,
  success,
  permissionDenied,
  serviceDisabled,
  error,
}

/// Sentinelle : distingue "ne pas toucher" de "effacer avec null".
const _unset = Object();

class LocationState {
  const LocationState({
    this.status = LocationStatus.initial,
    this.position,
    this.errorMessage,
  });

  final LocationStatus status;
  final GeoPoint? position;
  final String? errorMessage;

  /// [position] et [errorMessage] acceptent `null` pour effacer. Sans la
  /// sentinelle, `errorMessage: null` conserverait l'erreur précédente.
  LocationState copyWith({
    LocationStatus? status,
    Object? position = _unset,
    Object? errorMessage = _unset,
  }) {
    return LocationState(
      status: status ?? this.status,
      position: identical(position, _unset)
          ? this.position
          : position as GeoPoint?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
