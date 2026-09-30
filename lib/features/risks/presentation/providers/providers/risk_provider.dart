import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/risks/data/datasources/elevation_api_service.dart';
import 'package:salus/features/risks/data/datasources/gdacs_api_service.dart';
import 'package:salus/features/risks/data/repositories/risk_zone_repository_impl.dart';
import 'package:salus/features/risks/data/repositories/safe_zone_repository_impl.dart';
import 'package:salus/features/risks/data/services/turf_geofonce_service.dart';
import 'package:salus/features/risks/domain/repositories/risk_zone_repository.dart';
import 'package:salus/features/risks/domain/repositories/safe_zone.dart';
import 'package:salus/features/risks/domain/services/zone_geofence_service.dart';
import 'package:salus/features/risks/domain/usecases/get_dangerous_zone.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final gdacsApiServiceProvider =
    Provider((ref) => GdacsApiService(ref.watch(dioProvider)));

final riskZoneRepositoryProvider = Provider<RiskZoneRepository>(
  (ref) => RiskZoneRepositoryImpl(ref.watch(gdacsApiServiceProvider)),
);

final elevationApiServiceProvider =
    Provider((ref) => ElevationApiService(ref.watch(dioProvider)));

final safeZoneRepositoryProvider = Provider<SafeZoneRepository>(
  (ref) => SafeZoneRepositoryImpl(ref.watch(elevationApiServiceProvider)),
);

final geofenceServiceProvider =
    Provider<ZoneGeofenceService>((ref) => TurfGeofenceService());

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
      final g = z.geometry;
      final centroid = GeoPoint(
        g.map((p) => p.latitude).reduce((a, b) => a + b) / g.length,
        g.map((p) => p.longitude).reduce((a, b) => a + b) / g.length,
      );
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