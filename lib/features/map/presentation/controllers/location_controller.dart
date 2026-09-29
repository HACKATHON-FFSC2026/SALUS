import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/location_state.dart';

final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController();
});

/// StreamProvider fournissant la position GPS en temps réel
final userLocationStreamProvider = StreamProvider<Position>((ref) async* {
  // Vérification préalable des services avant d'écouter le stream
  final isEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isEnabled) {
    throw Exception('Services GPS désactivés');
  }

  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Mise à jour tous les 5 mètres de déplacement
  );

  yield* Geolocator.getPositionStream(locationSettings: locationSettings);
});

class LocationController extends StateNotifier<LocationState> {
  LocationController() : super(const LocationState());

  /// Vérifie et demande les permissions GPS
  Future<void> checkAndRequestPermission() async {
    state = state.copyWith(status: LocationStatus.loading);

    try {
      // 1. Vérifier si le service GPS est activé sur le téléphone
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: LocationStatus.serviceDisabled,
          errorMessage: 'Le service GPS est désactivé sur votre appareil.',
        );
        return;
      }

      // 2. Vérifier les autorisations accordées à l'application
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            status: LocationStatus.permissionDenied,
            errorMessage: 'La permission d\'accès à la géolocalisation a été refusée.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: LocationStatus.permissionDenied,
          errorMessage:
              'Les permissions GPS sont bloquées. Veuillez les activer dans les paramètres de votre téléphone.',
        );
        return;
      }

      // 3. Récupérer la première position de fixation
      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      state = state.copyWith(
        status: LocationStatus.success,
        position: currentPosition,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: LocationStatus.error,
        errorMessage: 'Erreur lors de la récupération du GPS : ${e.toString()}',
      );
    }
  }

  /// Ouvre les paramètres système de l'appareil
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Ouvre le menu d'activation du GPS
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}