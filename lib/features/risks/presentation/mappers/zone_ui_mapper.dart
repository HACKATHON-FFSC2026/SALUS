import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/core/entities/zone_entity.dart';

extension ZoneUiMapper on Zone {
  List<LatLng> get toLatLngList =>
      geometry.map((c) => LatLng(c.latitude, c.longitude)).toList();

  Color get borderColor {
    if (type == ZoneType.safe) return Colors.green;
    return switch (severity) {
      Severity.low => Colors.yellow.shade700,
      Severity.medium => Colors.orange,
      Severity.high => Colors.red,
      Severity.critical => Colors.purple,
      null => Colors.red,
    };
  }

  Color get fillColor {
    final alpha = type == ZoneType.safe
        ? 0.25
        : switch (severity) {
            Severity.low => 0.35,
            Severity.medium => 0.40,
            Severity.high => 0.45,
            Severity.critical => 0.55,
            null => 0.30,
          };
    return borderColor.withValues(alpha: alpha);
  }

  String get label => switch (disasterType) {
        DisasterType.earthquake => 'Séisme',
        DisasterType.tsunami => 'Tsunami',
        DisasterType.cyclone => 'Cyclone',
        DisasterType.flood => 'Inondation',
        DisasterType.landslide => 'Glissement de terrain',
        DisasterType.volcano => 'Volcan',
        _ => 'Catastrophe',
      };

  Polygon toPolygon() => Polygon(
        points: toLatLngList,
        color: fillColor,
        borderColor: borderColor,
        borderStrokeWidth: type == ZoneType.safe ? 1 : 2,
      );
}