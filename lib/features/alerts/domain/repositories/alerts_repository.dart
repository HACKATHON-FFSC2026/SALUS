import 'package:salus/core/entities/sos_alert_entity.dart';

abstract class IAlertsRepository {
  Future<void> createSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  });

  Future<void> cancelSos(String alertId);
  Future<void> respondToSos(String alertId);
  Future<void> resolveSos(String alertId, {String? resolutionType, String? resolutionNote});
  Stream<SOSAlert?> watchSosAlert(String alertId);
  Stream<List<SOSAlert>> watchActiveSosAlerts();
}
