import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/core/utils/geo_math.dart';
 
extension ZoneUiMapper on Zone {
  List<LatLng> get toLatLngList =>
      geometry.map((c) => LatLng(c.latitude, c.longitude)).toList();
 
  /// Point où placer l'icône (centre du cercle / du polygone).
  LatLng get center {
    final c = GeoMath.centroid(geometry);
    return LatLng(c.latitude, c.longitude);
  }
 
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

  /// Nature de la zone, lisible par l'utilisateur.
  /// ponytail: les zones sûres viennent uniquement de l'heuristique
  /// d'altitude; brancher la nature ici si une autre source est ajoutée.
  String get nature => switch (type) {
        ZoneType.safe => 'Élévation (terrain surélevé)',
        ZoneType.risk => label,
      };
 
  IconData get icon => switch (disasterType) {
        DisasterType.earthquake => Icons.warning_amber_rounded, // pas d'icône séisme dans cette version de Flutter
        DisasterType.tsunami => Icons.tsunami,
        DisasterType.cyclone => Icons.cyclone,
        DisasterType.flood => Icons.flood,
        DisasterType.landslide => Icons.landslide,
        DisasterType.volcano => Icons.volcano,
        _ => Icons.warning_amber_rounded,
      };
 
  /// `hitValue` porte la zone : identifie le polygone touché au clic
  /// (fiche via [LayerHitNotifier] sur la carte).
  Polygon<Zone> toPolygon() => Polygon<Zone>(
        points: toLatLngList,
        color: fillColor,
        borderColor: borderColor,
        borderStrokeWidth: type == ZoneType.safe ? 1 : 2,
        hitValue: this,
      );
}