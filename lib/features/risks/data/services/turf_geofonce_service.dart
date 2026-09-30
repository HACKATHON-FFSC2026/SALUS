import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:turf/turf.dart' as turf;
import '../../domain/services/zone_geofence_service.dart';

class TurfGeofenceService implements ZoneGeofenceService {
  @override
  bool isUserInZone(GeoPoint position, Zone zone) {
    if (zone.geometry.length < 3) return false;

    // Turf utilise [Longitude, Latitude]
    final userPoint = turf.Position(
      position.longitude,
      position.latitude,
    );

    final ring = zone.geometry
        .map((c) => turf.Position(c.longitude, c.latitude))
        .toList();

    // Fermeture du polygone : comparaison explicite (pas de == sur Position)
    final first = zone.geometry.first;
    final last = zone.geometry.last;
    if (first.latitude != last.latitude || first.longitude != last.longitude) {
      ring.add(ring.first);
    }

    final polygon = turf.Polygon(coordinates: [ring]);

    return turf.booleanPointInPolygon(userPoint, polygon, ignoreBoundary: false);
  }
}