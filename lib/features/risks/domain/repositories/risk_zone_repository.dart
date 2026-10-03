import 'package:salus/core/entities/zone_entity.dart';

abstract class RiskZoneRepository {
  /// Retourne les zones de risque actives (GDACS + zones manuelles Firestore)
  Future<List<Zone>> getActiveRiskZones();
}