import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/features/alerts/data/repositories/alert_read_repository.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import '../../data/repositories/shared_prefs_alert_read_repository.dart';
import '../../domain/entities/disaster_alert.dart';
import '../../domain/usecases/build_alerts_for_user.dart';
 
final alertReadRepositoryProvider = Provider<AlertReadRepository>(
  (ref) => SharedPrefsAlertReadRepository(),
);
 
final buildAlertsProvider = Provider<BuildAlertsForUser>(
  (ref) => BuildAlertsForUser(ref.watch(geofenceServiceProvider)),
);
 
/// Alertes personnalisées pour la position courante.
///
/// Recalculées quand les zones GDACS changent (toutes les 15 min) ou quand la
/// position change. Pour détecter qu'une catastrophe se rapproche, on compare
/// la distance actuelle à celle du PRÉCÉDENT rafraîchissement des zones
/// (`_baseline`), pas à celle du dernier calcul : sinon l'indicateur
/// clignoterait à chaque mise à jour GPS.
class AlertsNotifier extends Notifier<List<DisasterAlert>> {
  Map<String, double> _baseline = {};
  Map<String, double> _last = {};
 
  @override
  List<DisasterAlert> build() {
    ref.listen<AsyncValue<List<Zone>>>(riskZonesProvider, (prev, next) {
      if (!next.hasValue) return;
      // Pendant un rafraîchissement, la valeur précédente est conservée :
      // on ne repart de zéro que si de nouvelles données sont arrivées.
      if (identical(prev?.value, next.value)) return;
      _baseline = _last;
      state = _compute();
    });
    ref.listen(locationProvider.select((s) => s.position), (_, _) {
      state = _compute();
    });
    return _compute();
  }
 
  List<DisasterAlert> _compute() {
    final zones = ref.read(riskZonesProvider).value ?? const <Zone>[];
    final pos = ref.read(locationProvider).position;
    if (pos == null) return const [];
 
    final alerts = ref.read(buildAlertsProvider)(
      position: GeoPoint(pos.latitude, pos.longitude),
      zones: zones,
      previousDistancesKm: _baseline,
    );
    _last = {for (final a in alerts) a.zoneId: a.distanceKm};
    return alerts;
  }
}
 
final alertsProvider = NotifierProvider<AlertsNotifier, List<DisasterAlert>>(
  AlertsNotifier.new,
);
 
/// Ids des alertes déjà lues (persistés sur l'appareil).
class ReadAlertIdsNotifier extends AsyncNotifier<Set<String>> {
  static const _maxStored = 300;
 
  @override
  Future<Set<String>> build() =>
      ref.read(alertReadRepositoryProvider).getReadIds();
 
  Future<void> markRead(Iterable<String> ids) async {
    final current = await future; // évite d'écraser le stockage pendant le chargement
    final next = {...current, ...ids};
    if (next.length == current.length) return;
 
    final capped = next.length > _maxStored
        ? next.toList().sublist(next.length - _maxStored).toSet()
        : next;
    if (!ref.mounted) return;
    state = AsyncData(capped);
    await ref.read(alertReadRepositoryProvider).saveReadIds(capped);
  }
 
  Future<void> markAllRead() =>
      markRead(ref.read(alertsProvider).map((a) => a.id));
}
 
final readAlertIdsProvider =
    AsyncNotifierProvider<ReadAlertIdsNotifier, Set<String>>(
  ReadAlertIdsNotifier.new,
);
 
/// Nombre d'alertes non lues, pour le badge de l'onglet Alertes.
final unreadAlertsCountProvider = Provider<int>((ref) {
  final read = ref.watch(readAlertIdsProvider).value;
  if (read == null) return 0; // état lu pas encore chargé : pas de faux badge
  return ref.watch(alertsProvider).where((a) => !read.contains(a.id)).length;
});