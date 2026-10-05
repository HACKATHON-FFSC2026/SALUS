import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/utils/geo_grid.dart';
import 'package:salus/app/di/app_dependencies.dart';

/// Position de référence si la permission est déjà accordée.
///
/// `getLastKnownPosition` ne déclenche aucune boîte de dialogue, contrairement
/// à `getCurrentPosition`, et suffit à trier une liste d'alertes. Exposée à
/// l'UI pour qu'elle distingue une liste « à proximité » d'une liste globale :
/// sans permission, il n'y a pas de distance et le titre ne doit pas mentir.
final sosOriginProvider = FutureProvider.autoDispose<Position?>(
  (ref) => _permittedPosition(),
);

/// Alertes SOS actives, triées par proximité quand la position est connue.
///
/// La permission de localisation n'est jamais demandée ici : une liste qui
/// s'ouvre depuis l'accueil n'a pas à faire apparaître une boîte de dialogue
/// système. Sans permission déjà accordée, on retombe sur la liste globale.
final activeSosStreamProvider = StreamProvider.autoDispose<List<SOSAlert>>((
  ref,
) async* {
  final repository = ref.watch(sosRepositoryProvider);
  final origin = await ref.watch(sosOriginProvider.future);

  await for (final alerts in repository.watchActiveSosAlerts(
    geoCells: origin == null
        ? null
        : GeoGrid.cellsAround(origin.latitude, origin.longitude),
  )) {
    if (origin == null) {
      yield alerts;
      continue;
    }

    final sorted = alerts
        .map((sos) => sos.withDistanceFrom(latitude: origin.latitude, longitude: origin.longitude))
        .toList()
      ..sort((a, b) => (a.distanceInKm ?? 0).compareTo(b.distanceInKm ?? 0));
    yield sorted;
  }
});

/// Position de référence si la permission est déjà accordée.
///
/// `getLastKnownPosition` ne déclenche aucune boîte de dialogue, contrairement
/// à `getCurrentPosition`, et suffit à trier une liste d'alertes.
Future<Position?> _permittedPosition() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getLastKnownPosition();
  } catch (_) {
    return null;
  }
}
