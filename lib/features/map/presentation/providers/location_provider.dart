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
  ///
  /// Toutes les écritures passent par [_publish] : la carte peut quitter
  /// l'écran pendant le dialogue de permission, et Riverpod lève sur une
  /// écriture dans `state` d'un notifier déjà disposé.
  Future<void> refresh() async {
    // ponytail: un seul GPS à la fois. Sans ça, initState + tap FAB lancent
    // 2 dialogues permission + 2 fixations en parallèle.
    if (state.status == LocationStatus.loading) return;
    final previousPosition = state.position;
    _publish(state.copyWith(status: LocationStatus.loading));
    try {
      final position = await ref
          .read(locationRepositoryProvider)
          .currentPosition();
      _publish(
        state.copyWith(
          status: LocationStatus.success,
          position: position,
          errorMessage: null,
        ),
      );
    } on LocationFailureException catch (e) {
      _publish(
        // ponytail: on garde la dernière position connue, un timeout
        // transitoire ne doit pas faire disparaître la pastille bleue.
        LocationState(
          status: _statusOf(e.failure),
          position: previousPosition,
          errorMessage: _messageOf(e.failure),
        ),
      );
    } catch (e) {
      _publish(
        LocationState(
          status: LocationStatus.error,
          position: previousPosition,
          errorMessage: 'Erreur lors de la récupération du GPS : $e',
        ),
      );
    }
  }

  void _publish(LocationState next) {
    if (!ref.mounted) return;
    state = next;
  }

  static LocationStatus _statusOf(LocationFailure failure) => switch (failure) {
    LocationFailure.serviceDisabled => LocationStatus.serviceDisabled,
    LocationFailure.permissionDenied ||
    LocationFailure.permissionDeniedForever => LocationStatus.permissionDenied,
    LocationFailure.timeout ||
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
    LocationFailure.timeout =>
      'Pas de signal GPS. Réessayez dans quelques instants.',
    LocationFailure.unknown =>
      'Erreur lors de la récupération du GPS.',
  };
}
