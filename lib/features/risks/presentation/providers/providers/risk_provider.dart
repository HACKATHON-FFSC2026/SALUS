import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/core/utils/geo_math.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/risks/domain/usecases/get_dangerous_zone.dart';

final getDangerousZonesProvider = Provider(
  (ref) => GetDangerousZonesForUser(ref.watch(geofenceServiceProvider)),
);

/// Toutes les zones à risque actives (pour la carte), rafraîchies toutes les 15 min.
final riskZonesProvider = FutureProvider<List<Zone>>((ref) async {
  final timer = Timer(const Duration(minutes: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(riskZoneRepositoryProvider).getActiveRiskZones();
});

/// Zones sûres brutes : recalculées seulement si l'utilisateur bouge de ~1 km.
final _rawSafeZonesProvider = FutureProvider<List<Zone>>((ref) async {
  final key = ref.watch(locationProvider.select((s) {
    final p = s.position;
    if (p == null) return null;
    return (lat: (p.latitude * 100).round(), lng: (p.longitude * 100).round());
  }));
  if (key == null) return [];
  return ref
      .watch(safeZoneRepositoryProvider)
      .getSafeZonesAround(GeoPoint(key.lat / 100, key.lng / 100));
});

/// Zones sûres SANS celles qui tombent dans une zone à risque active :
/// une zone "sûre" au milieu d'une inondation serait trompeuse.
final filteredSafeZonesProvider = Provider<AsyncValue<List<Zone>>>((ref) {
  final risks = ref.watch(riskZonesProvider).value ?? const <Zone>[];
  final geofence = ref.watch(geofenceServiceProvider);

  return ref.watch(_rawSafeZonesProvider).whenData((safe) {
    return safe.where((z) {
      // ponytail: géométrie vide => pas de centroïde, zone inexploitable sur carte.
      if (z.geometry.isEmpty) return false;
      final c = GeoMath.centroid(z.geometry);
      final centroid = GeoPoint(c.latitude, c.longitude);
      return !risks.any((r) =>
          r.isActive && r.type == ZoneType.risk && geofence.isUserInZone(centroid, r));
    }).toList();
  });
});

/// Zones à risque contenant l'utilisateur (alerte).
final dangerousZonesProvider = Provider<List<Zone>>((ref) {
  final zones = ref.watch(riskZonesProvider).value ?? const <Zone>[];
  final pos = ref.watch(locationProvider).position;
  if (pos == null) return const [];
  return ref.watch(getDangerousZonesProvider)(
    GeoPoint(pos.latitude, pos.longitude),
    zones,
  );
});
