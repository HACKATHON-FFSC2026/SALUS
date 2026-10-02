import 'package:salus/core/entities/sos_alert_entity.dart';
import '../repositories/alerts_repository.dart';

class ManageSosAlertsUseCase {
  final IAlertsRepository _repository;

  ManageSosAlertsUseCase(this._repository);

  Future<void> create({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) {
    return _repository.createSos(
      latitude: latitude,
      longitude: longitude,
      distressType: distressType,
      description: description,
    );
  }

  Future<void> cancel(String alertId) => _repository.cancelSos(alertId);

  Future<void> respond(String alertId) => _repository.respondToSos(alertId);

  Future<void> resolve(String alertId, {String? resolutionType, String? resolutionNote}) =>
      _repository.resolveSos(alertId, resolutionType: resolutionType, resolutionNote: resolutionNote);

  Stream<SOSAlert?> watchAlert(String alertId) =>
      _repository.watchSosAlert(alertId);

  Stream<List<SOSAlert>> watchActiveAlerts() =>
      _repository.watchActiveSosAlerts();
}
