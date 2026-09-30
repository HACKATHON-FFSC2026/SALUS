import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/zone_entity.dart';

import '../services/zone_geofence_service.dart';

class IsUserInZone {
  final ZoneGeofenceService _geofenceService;

  IsUserInZone(this._geofenceService);

  bool call(GeoPoint position, Zone zone) {
    return _geofenceService.isUserInZone(position, zone);
  }
}