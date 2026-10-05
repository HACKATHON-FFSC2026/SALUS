import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/risks/domain/services/zone_geofence_service.dart';

class FindSheltersInRiskZones {
  const FindSheltersInRiskZones(this._geofence);

  final ZoneGeofenceService _geofence;

  Set<String> call({
    required List<Shelter> shelters,
    required List<Zone> zones,
  }) {
    final activeRiskZones = zones.where(
      (zone) =>
          zone.isActive &&
          zone.type == ZoneType.risk &&
          zone.geometry.length >= 3,
    );
    return {
      for (final shelter in shelters)
        if (activeRiskZones.any(
          (zone) => _geofence.isUserInZone(shelter.location, zone),
        ))
          shelter.id,
    };
  }
}
