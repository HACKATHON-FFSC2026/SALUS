import 'package:salus/core/entities/sos_alert_entity.dart';
import '../repositories/sos_repository.dart';

class WatchSosUseCase {
  final ISosRepository _repository;

  WatchSosUseCase(this._repository);

  Stream<SOSAlert?> execute(String alertId) {
    return _repository.watchSosAlert(alertId);
  }
}