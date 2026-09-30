import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import '../../data/repositories/sos_repository_impl.dart';

final activeSosStreamProvider = StreamProvider.autoDispose<List<SOSAlert>>((ref) async* {
  final repository = ref.watch(sosRepositoryProvider);

  // Position actuelle de l'utilisateur
  Position? currentPosition;
  try {
    currentPosition = await Geolocator.getCurrentPosition();
  } catch (_) {
    currentPosition = null;
  }

  await for (final alerts in repository.watchActiveSosAlerts()) {
    if (currentPosition != null) {
      final processedAlerts = alerts.map((sos) {
        final distanceInMeters = Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition.longitude,
          sos.location.latitude,
          sos.location.longitude,
        );
        return sos.copyWith(distanceInKm: distanceInMeters / 1000);
      }).toList();

      // Tri par distance la plus proche
      processedAlerts.sort((a, b) => (a.distanceInKm ?? 0).compareTo(b.distanceInKm ?? 0));
      yield processedAlerts;
    } else {
      yield alerts;
    }
  }
});