import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/sos/data/datasources/sos_remote_datasource.dart';
import 'package:salus/features/sos/domain/repositories/sos_repository.dart';

final sosRemoteDataSourceProvider = Provider<ISosRemoteDataSource>((ref) {
  return SosRemoteDataSourceImpl();
});

final sosRepositoryProvider = Provider<ISosRepository>((ref) {
  return SosRepositoryImpl(ref.watch(sosRemoteDataSourceProvider));
});

class SosRepositoryImpl implements ISosRepository {
  const SosRepositoryImpl(this._remoteDataSource);

  final ISosRemoteDataSource _remoteDataSource;

  @override
  Future<String> sendSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) {
    return _remoteDataSource.createSosAlert(
      latitude: latitude,
      longitude: longitude,
      distressType: distressType,
      description: description,
    );
  }

  @override
  Stream<SOSAlert?> watchSosAlert(String alertId) {
    return _remoteDataSource.watchSosAlert(alertId);
  }

  @override
  Future<void> cancelSos(String alertId) {
    return _remoteDataSource.cancelSosAlert(alertId);
  }

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts({List<String>? geoCells}) {
    return _remoteDataSource.watchActiveSosAlerts(geoCells: geoCells);
  }

  @override
  Stream<List<SOSAlert>> watchMyActiveSosAlerts() {
    return _remoteDataSource.watchMyActiveSosAlerts();
  }

  @override
  Future<void> respondToSos(String alertId) {
    return _remoteDataSource.respondToSos(alertId);
  }

  @override
  Future<void> shareLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) {
    return _remoteDataSource.shareSosLocation(
      alertId: alertId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}