import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/core/entities/zone_entity.dart';

abstract class SafeZoneRepository {
  Future<List<Zone>> getSafeZonesAround(GeoPoint center);
}