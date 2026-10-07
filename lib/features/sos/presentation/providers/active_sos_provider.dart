import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/utils/geo_grid.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';

/// Position de référence si la permission est déjà accordée.
///
/// `getLastKnownPosition` ne déclenche aucune boîte de dialogue, contrairement
/// à `getCurrentPosition`, et suffit à trier une liste d'alertes. Exposée à
/// l'UI pour qu'elle distingue une liste « à proximité » d'une liste globale :
/// sans permission, il n'y a pas de distance et le titre ne doit pas mentir.
final sosOriginProvider = FutureProvider.autoDispose<Position?>(
  (ref) => _permittedPosition(),
);

/// Portée de la liste SOS.
///
/// `false` (défaut) : toutes les alertes. `true` : limitée aux cellules proches
/// de l'utilisateur. La vue « proche » peut être vide alors que des alertes
/// existent ailleurs — le basculement évite d'y rester coincé.
class SosNearbyScope extends Notifier<bool> {
  @override
  bool build() => false;

  void setNearby(bool value) => state = value;
}

final sosNearbyScopeProvider = NotifierProvider<SosNearbyScope, bool>(
  SosNearbyScope.new,
);

/// Alertes SOS actives, triées par proximité quand la position est connue.
///
/// La permission de localisation n'est jamais demandée ici : une liste qui
/// s'ouvre depuis l'accueil n'a pas à faire apparaître une boîte de dialogue
/// système. Sans permission déjà accordée, on retombe sur la liste globale.
final activeSosStreamProvider = StreamProvider.autoDispose<List<SOSAlert>>((
  ref,
) async* {
  // Invité : Firestore refuse la lecture des alertes SOS. Ne pas lancer la
  // requête, la liste resterait vide de toute façon.
  if (ref.watch(currentUidProvider) == null) {
    yield const <SOSAlert>[];
    return;
  }

  final repository = ref.watch(sosRepositoryProvider);
  final origin = await ref.watch(sosOriginProvider.future);
  final nearbyOnly = ref.watch(sosNearbyScopeProvider);

  await for (final alerts in repository.watchActiveSosAlerts(
    geoCells: nearbyOnly && origin != null
        ? GeoGrid.cellsAround(origin.latitude, origin.longitude)
        : null,
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
