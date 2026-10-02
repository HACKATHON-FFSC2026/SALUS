import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/core/utils/geo_math.dart';
import 'package:salus/features/risks/domain/services/zone_geofence_service.dart';
 
import '../entities/disaster_alert.dart';
 
/// Logique métier pure : transforme les zones à risque actives en alertes
/// personnalisées (distance, direction, rapprochement) pour une position donnée.
class BuildAlertsForUser {
  final ZoneGeofenceService _geofence;
  BuildAlertsForUser(this._geofence);
 
  /// En dessous, on considère que la variation est du bruit (centre GDACS qui bouge, etc.).
  static const _approachThresholdKm = 10.0;
 
  List<DisasterAlert> call({
    required GeoPoint position,
    required List<Zone> zones,
 
    /// Distances connues lors du calcul précédent, indexées par `zone.id`.
    /// Sert à détecter qu'une catastrophe se rapproche.
    Map<String, double> previousDistancesKm = const {},
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final alerts = <DisasterAlert>[];
 
    for (final zone in zones) {
      if (!zone.isActive || zone.type != ZoneType.risk) continue;
      if (zone.severity == Severity.low) continue; // seuls orange / rouge alertent
      if (zone.geometry.length < 3) continue;
 
      final hazard = zone.disasterType ?? DisasterType.other;
      final center = GeoMath.centroid(zone.geometry);
      final distance = GeoMath.distanceKm(position, center);
      final inside = _geofence.isUserInZone(position, zone);
 
      if (!inside && distance > _alertRadiusKm(hazard)) continue;
 
      final previous = previousDistancesKm[zone.id];
      final approaching =
          !inside && previous != null && distance < previous - _approachThresholdKm;
      final bearing = GeoMath.bearingDegrees(position, center);
 
      alerts.add(DisasterAlert(
        id: '${zone.id}-${zone.severity?.name ?? 'unknown'}',
        zoneId: zone.id,
        disasterType: hazard,
        severity: zone.severity,
        title: _title(hazard, zone.severity),
        message: _message(
          hazard: hazard,
          inside: inside,
          approaching: approaching,
          distanceKm: distance,
          bearing: bearing,
        ),
        distanceKm: distance,
        bearingDeg: bearing,
        approaching: approaching,
        userInsideZone: inside,
        createdAt: at,
      ));
    }
 
    // Dans la zone d'abord, puis par distance croissante.
    alerts.sort((a, b) {
      if (a.userInsideZone != b.userInsideZone) return a.userInsideZone ? -1 : 1;
      return a.distanceKm.compareTo(b.distanceKm);
    });
    return alerts;
  }
 
  /// Rayon de vigilance autour du centre de l'événement (à ajuster avec le terrain).
  double _alertRadiusKm(DisasterType t) => switch (t) {
        DisasterType.cyclone => 1500,
        DisasterType.tsunami => 1000,
        DisasterType.earthquake => 500,
        DisasterType.flood => 300,
        DisasterType.volcano => 300,
        DisasterType.landslide => 200,
        DisasterType.other => 300,
      };
 
  (String article, String noun) _hazard(DisasterType t) => switch (t) {
        DisasterType.cyclone => ('un', 'cyclone tropical'),
        DisasterType.tsunami => ('un', 'tsunami'),
        DisasterType.earthquake => ('un', 'séisme'),
        DisasterType.flood => ('une', 'inondation'),
        DisasterType.volcano => ('une', 'activité volcanique'),
        DisasterType.landslide => ('un', 'glissement de terrain'),
        DisasterType.other => ('une', 'catastrophe naturelle'),
      };
 
  String _title(DisasterType t, Severity? s) {
    final level = switch (s) {
      Severity.critical => 'Alerte maximale',
      Severity.high => 'Alerte rouge',
      Severity.medium => 'Alerte orange',
      _ => 'Information',
    };
    return '$level · ${_capitalize(_hazard(t).$2)}';
  }
 
  String _message({
    required DisasterType hazard,
    required bool inside,
    required bool approaching,
    required double distanceKm,
    required double bearing,
  }) {
    final (article, noun) = _hazard(hazard);
    if (inside) {
      return 'Vous vous trouvez dans la zone d\'impact estimée ($noun). '
          'Suivez les consignes des autorités locales.';
    }
    final km = distanceKm >= 100
        ? ((distanceKm / 10).round() * 10)
        : distanceKm.round();
    final direction = GeoMath.cardinalFr(bearing);
    final trend = approaching ? ' et se rapproche' : '';
    return '${_capitalize('$article $noun')} se trouve à $km km $direction '
        'de votre position$trend. Restez informé et préparez-vous.';
  }
 
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
 