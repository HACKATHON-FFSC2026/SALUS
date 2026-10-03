import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/sos/data/datasources/sos_remote_datasource.dart';
import 'package:salus/core/entities/help_response_entity.dart';
import 'package:salus/core/entities/location_share_entity.dart';
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
  Future<String> offerHelp({
    required String alertId,
    ResponseType responseType = ResponseType.comingInPerson,
    String? message,
  }) {
    return _remoteDataSource.createHelpResponse(
      alertId: alertId,
      responseType: responseType,
      message: message,
    );
  }

  @override
  Future<void> setHelpStatus({
    required String responseId,
    required HelpResponseStatus status,
  }) {
    return _remoteDataSource.setHelpResponseStatus(
      responseId: responseId,
      status: status,
    );
  }

  @override
  Stream<List<HelpResponse>> watchHelpResponses(String alertId) {
    return _remoteDataSource.watchHelpResponses(alertId);
  }

  @override
  Future<void> shareResponderLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) {
    return _remoteDataSource.shareResponderLocation(
      alertId: alertId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<void> stopResponderLocation(String alertId) {
    return _remoteDataSource.stopResponderLocation(alertId);
  }

  @override
  Stream<List<LocationShare>> watchResponderLocations(String alertId) {
    return _remoteDataSource.watchResponderLocations(alertId);
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