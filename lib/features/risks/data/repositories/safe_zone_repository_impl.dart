import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/features/risks/domain/repositories/safe_zone.dart';
import '../datasources/elevation_api_service.dart';

class SafeZoneRepositoryImpl implements SafeZoneRepository {
  final ElevationApiService _api;
  SafeZoneRepositoryImpl(this._api);

  static const _radiusCells = 4; // grille 9x9 = 81 points
  static const _stepDeg = 0.005; // ≈ 550 m
  static const _minReliefM = 15.0; // altitude mini au-dessus du point le plus bas

  @override
  Future<List<Zone>> getSafeZonesAround(GeoPoint center) async {
    // On aligne le centre sur la grille : cellules stables d'un appel à l'autre.
    final cLat = (center.latitude / _stepDeg).round() * _stepDeg;
    final cLng = (center.longitude / _stepDeg).round() * _stepDeg;

    final centers = <GeoPoint>[
      for (var i = -_radiusCells; i <= _radiusCells; i++)
        for (var j = -_radiusCells; j <= _radiusCells; j++)
          GeoPoint(cLat + i * _stepDeg, cLng + j * _stepDeg),
    ];

    final elevations = await _api.fetchElevations(centers);
    final threshold = elevations.reduce(math.min) + _minReliefM;
    const h = _stepDeg / 2;
    final now = DateTime.now();

    final zones = <Zone>[];
    for (var k = 0; k < centers.length; k++) {
      if (elevations[k] < threshold) continue;
      final c = centers[k];
      zones.add(Zone(
        id: 'safe-${c.latitude.toStringAsFixed(4)}_${c.longitude.toStringAsFixed(4)}',
        type: ZoneType.safe,
        geometry: [
          GeoPoint(c.latitude - h, c.longitude - h),
          GeoPoint(c.latitude - h, c.longitude + h),
          GeoPoint(c.latitude + h, c.longitude + h),
          GeoPoint(c.latitude + h, c.longitude - h),
        ],
        origin: ZoneOrigin.automatic,
        source: 'Open-Meteo Elevation (heuristique)',
        startedAt: now,
      ));
    }
    return zones;
  }
}