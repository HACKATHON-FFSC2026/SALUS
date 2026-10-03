import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/zone_entity.dart';

import '../services/zone_geofence_service.dart';

class GetDangerousZonesForUser {
  final ZoneGeofenceService _geofenceService;

  GetDangerousZonesForUser(this._geofenceService);

  /// Filtre les zones : actives, de type risk, et contenant la position.
  /// Logique métier pure — testable sans GPS ni Turf.
  List<Zone> call(GeoPoint? position, List<Zone> zones) {
    if (position == null) return [];

    return zones.where((zone) {
      return zone.isActive &&
          zone.type == ZoneType.risk &&
          _geofenceService.isUserInZone(position, zone);
    }).toList();
  }
}