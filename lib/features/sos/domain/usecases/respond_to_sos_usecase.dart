import '../repositories/sos_repository.dart';

class RespondToSosUseCase {
  RespondToSosUseCase(this._repository);

  final ISosRepository _repository;

  /// Se déclare intervenant sur une alerte. Idempotent.
  Future<void> execute(String alertId) async {
    if (alertId.isEmpty) return;
    await _repository.respondToSos(alertId);
  }
}