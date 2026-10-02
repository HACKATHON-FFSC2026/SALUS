import 'dart:math' as math;
 
import 'package:cloud_firestore/cloud_firestore.dart';
 
/// Calculs géographiques purs : aucune dépendance Flutter, testables unitairement.
abstract final class GeoMath {
  static const double _earthRadiusKm = 6371.0;
 
  static double _rad(double deg) => deg * math.pi / 180;
 
  /// Distance orthodromique (formule de Haversine), en km.
  static double distanceKm(GeoPoint a, GeoPoint b) {
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(h));
  }
 
  /// Cap initial de [from] vers [to], en degrés (0 = nord, 90 = est).
  static double bearingDegrees(GeoPoint from, GeoPoint to) {
    final p1 = _rad(from.latitude);
    final p2 = _rad(to.latitude);
    final dl = _rad(to.longitude - from.longitude);
    final y = math.sin(dl) * math.cos(p2);
    final x = math.cos(p1) * math.sin(p2) -
        math.sin(p1) * math.cos(p2) * math.cos(dl);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
 
  /// Centre approximatif d'un polygone (moyenne des sommets).
  /// Suffisant pour nos cercles GDACS. Limite : imprécis si le polygone
  /// traverse l'antiméridien (±180°).
  static GeoPoint centroid(List<GeoPoint> points) {
    if (points.isEmpty) return const GeoPoint(0, 0);
    var pts = points;
    final first = points.first;
    final last = points.last;
    if (points.length > 1 &&
        first.latitude == last.latitude &&
        first.longitude == last.longitude) {
      pts = points.sublist(0, points.length - 1); // anneau fermé : on retire le doublon
    }
    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return GeoPoint(lat, lng);
  }
 
  /// Direction cardinale en français, prête à être insérée dans une phrase
  /// ("au sud-ouest", "à l'est"...).
  static String cardinalFr(double bearing) {
    const dirs = [
      'au nord',
      'au nord-est',
      "à l'est",
      'au sud-est',
      'au sud',
      'au sud-ouest',
      "à l'ouest",
      'au nord-ouest',
    ];
    return dirs[((bearing + 22.5) / 45).floor() % 8];
  }
}
 