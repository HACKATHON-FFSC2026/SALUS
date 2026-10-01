import '../repositories/sos_repository.dart';

class CancelSosUseCase {
  CancelSosUseCase(this._repository);

  final ISosRepository _repository;

  /// « Je suis en sécurité ». Le statut final vient du flux temps réel, pas de
  /// cet appel: l'écriture peut être mise en file d'attente hors-ligne.
  Future<void> execute(String alertId) async {
    if (alertId.isEmpty) return;
    await _repository.cancelSos(alertId);
  }
}