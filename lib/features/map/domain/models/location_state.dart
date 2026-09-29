import 'package:geolocator/geolocator.dart';

enum LocationStatus { initial, loading, success, permissionDenied, serviceDisabled, error }

class LocationState {
  final LocationStatus status;
  final Position? position;
  final String? errorMessage;

  const LocationState({
    this.status = LocationStatus.initial,
    this.position,
    this.errorMessage,
  });

  LocationState copyWith({
    LocationStatus? status,
    Position? position,
    String? errorMessage,
  }) {
    return LocationState(
      status: status ?? this.status,
      position: position ?? this.position,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}