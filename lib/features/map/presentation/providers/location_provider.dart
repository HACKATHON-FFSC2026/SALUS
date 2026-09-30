import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/features/map/data/geolocator_location_repository.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/domain/location_repository.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => const GeolocatorLocationRepository(),
);

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);

/// Traduit les échecs du port en état d'interface. Aucune règle GPS ici :
/// service et permissions appartiennent au repository.
class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  /// Demande la permission si besoin puis publie la première fixation.
  Future<void> refresh() async {
    state = state.copyWith(status: LocationStatus.loading);
    try {
      final position = await ref
          .read(locationRepositoryProvider)
          .currentPosition();
      state = state.copyWith(
        status: LocationStatus.success,
        position: position,
        errorMessage: null,
      );
    } on LocationFailureException catch (e) {
      state = LocationState(
        status: _statusOf(e.failure),
        errorMessage: _messageOf(e.failure),
      );
    } catch (e) {
      state = LocationState(
        status: LocationStatus.error,
        errorMessage: 'Erreur lors de la récupération du GPS : $e',
      );
    }
  }

  static LocationStatus _statusOf(LocationFailure failure) => switch (failure) {
    LocationFailure.serviceDisabled => LocationStatus.serviceDisabled,
    LocationFailure.permissionDenied ||
    LocationFailure.permissionDeniedForever => LocationStatus.permissionDenied,
    LocationFailure.unknown => LocationStatus.error,
  };

  static String _messageOf(LocationFailure failure) => switch (failure) {
    LocationFailure.serviceDisabled =>
      'Le service GPS est désactivé sur votre appareil.',
    LocationFailure.permissionDenied =>
      "La permission d'accès à la géolocalisation a été refusée.",
    LocationFailure.permissionDeniedForever =>
      'Les permissions GPS sont bloquées. Veuillez les activer dans les '
          'paramètres de votre téléphone.',
    LocationFailure.unknown =>
      'Erreur lors de la récupération du GPS.',
  };
}
