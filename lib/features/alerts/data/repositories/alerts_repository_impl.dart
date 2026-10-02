
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/alerts/data/datasources/alerts_remote_datasource.dart';
import 'package:salus/features/alerts/domain/repositories/alerts_repository.dart';

class AlertsRepositoryImpl implements IAlertsRepository {
  final IAlertsRemoteDataSource _dataSource;

  AlertsRepositoryImpl(this._dataSource);

  @override
  Future<void> createSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) {
    return _dataSource.createSosAlert(
      latitude: latitude,
      longitude: longitude,
      distressType: distressType,
      description: description,
    );
  }

  @override
  Future<void> cancelSos(String alertId) => _dataSource.cancelSosAlert(alertId);

  @override
  Future<void> respondToSos(String alertId) =>
      _dataSource.respondToSos(alertId);

  @override
  Future<void> resolveSos(String alertId, {String? resolutionType, String? resolutionNote}) =>
      _dataSource.resolveSosAlert(alertId, resolutionType: resolutionType, resolutionNote: resolutionNote);

  @override
  Stream<SOSAlert?> watchSosAlert(String alertId) =>
      _dataSource.watchSosAlert(alertId);

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts() =>
      _dataSource.watchActiveSosAlerts();
}
