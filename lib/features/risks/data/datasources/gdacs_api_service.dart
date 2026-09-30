// data/datasources/gdacs_api_service.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:salus/core/entities/zone_entity.dart';

class GdacsApiService {
  final Dio _dio;
  GdacsApiService(this._dio);

  static const _url =
      'https://www.gdacs.org/gdacsapi/api/events/geteventlist/EVENTS4APP';

  Future<List<Zone>> fetchPublicRiskZones() async {
    final response = await _dio.get<dynamic>(_url);
    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    final features = (data['features'] as List<dynamic>?) ?? [];

    final zones = <Zone>[];
    for (final raw in features) {
      final feature = raw as Map<String, dynamic>;
      final props = (feature['properties'] as Map<String, dynamic>?) ?? {};
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      if (props['iscurrent']?.toString().toLowerCase() == 'false') continue;

      final disaster = _mapDisasterType(props['eventtype']?.toString());
      final severity = _mapSeverity(props['alertlevel']?.toString());
      final rings = _extractRings(geometry, disaster, severity);
      final eventKey = '${props['eventtype']}-${props['eventid']}';

      for (var i = 0; i < rings.length; i++) {
        zones.add(Zone(
          id: rings.length == 1 ? 'gdacs-$eventKey' : 'gdacs-$eventKey-$i',
          type: ZoneType.risk,
          disasterType: disaster,
          geometry: rings[i],
          severity: severity,
          origin: ZoneOrigin.automatic,
          source: 'GDACS Public API',
          isActive: true,
          startedAt:
              DateTime.tryParse(props['fromdate']?.toString() ?? '') ??
                  DateTime.now(),
          endedAt: DateTime.tryParse(props['todate']?.toString() ?? ''),
        ));
      }
    }
    return zones.where((z) => z.geometry.length >= 3).toList();
  }

  List<List<GeoPoint>> _extractRings(
    Map<String, dynamic> g,
    DisasterType type,
    Severity? severity,
  ) {
    final coords = g['coordinates'];
    switch (g['type']) {
      case 'Point':
        final c = coords as List<dynamic>;
        return [
          _circle(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
            _radiusKm(type, severity),
          ),
        ];
      case 'Polygon':
        return [_toGeoPoints((coords as List).first as List)];
      case 'MultiPolygon':
        return [
          for (final poly in coords as List)
            _toGeoPoints((poly as List).first as List),
        ];
      default:
        return [];
    }
  }

  // GeoJSON = [lng, lat]
  List<GeoPoint> _toGeoPoints(List<dynamic> ring) => ring
      .map((c) => GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()))
      .toList();

  /// Rayon approximatif : GDACS ne fournit que le centre dans ce flux.
  double _radiusKm(DisasterType t, Severity? s) {
    final base = switch (t) {
      DisasterType.cyclone => 150.0,
      DisasterType.tsunami => 60.0,
      DisasterType.earthquake => 40.0,
      DisasterType.flood => 40.0,
      DisasterType.volcano => 25.0,
      _ => 30.0,
    };
    final factor = switch (s) {
      Severity.low => 0.6,
      Severity.medium => 1.0,
      Severity.high => 1.5,
      Severity.critical => 2.0,
      null => 0.8,
    };
    return base * factor;
  }

  List<GeoPoint> _circle(double lat, double lng, double radiusKm,
      {int steps = 36}) {
    const earthKm = 6371.0;
    final latR = lat * math.pi / 180;
    final lngR = lng * math.pi / 180;
    final d = radiusKm / earthKm;
    final points = <GeoPoint>[];
    for (var i = 0; i < steps; i++) {
      final b = 2 * math.pi * i / steps;
      final lat2 = math.asin(
        math.sin(latR) * math.cos(d) +
            math.cos(latR) * math.sin(d) * math.cos(b),
      );
      final lng2 = lngR +
          math.atan2(
            math.sin(b) * math.sin(d) * math.cos(latR),
            math.cos(d) - math.sin(latR) * math.sin(lat2),
          );
      points.add(GeoPoint(
        lat2 * 180 / math.pi,
        ((lng2 * 180 / math.pi + 540) % 360) - 180,
      ));
    }
    return points;
  }

  DisasterType _mapDisasterType(String? type) {
    switch (type?.toUpperCase()) {
      case 'FL': return DisasterType.flood;
      case 'TC': return DisasterType.cyclone;
      case 'EQ': return DisasterType.earthquake;
      case 'TS': return DisasterType.tsunami;
      case 'VO': return DisasterType.volcano;
      default: return DisasterType.other; // DR (sécheresse), WF (feu)...
    }
  }

  Severity? _mapSeverity(String? level) {
    switch (level?.toLowerCase()) {
      case 'green': return Severity.low;
      case 'orange': return Severity.medium;
      case 'red': return Severity.high;
      default: return null;
    }
  }
}