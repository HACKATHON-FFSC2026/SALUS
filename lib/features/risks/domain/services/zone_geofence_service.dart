import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/zone_entity.dart';


abstract class ZoneGeofenceService {
  /// Vérifie si une position est à l'intérieur du polygone d'une zone
  bool isUserInZone(GeoPoint position, Zone zone);
}