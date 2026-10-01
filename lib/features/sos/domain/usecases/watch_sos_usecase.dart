import 'package:salus/core/entities/sos_alert_entity.dart';
import '../repositories/sos_repository.dart';

class WatchSosUseCase {
  WatchSosUseCase(this._repository);

  final ISosRepository _repository;

  /// Émet `null` quand l'alerte a disparu du serveur (supprimée, ou lue par
  /// un document devenu illisible).
  Stream<SOSAlert?> execute(String alertId) {
    return _repository.watchSosAlert(alertId);
  }
}