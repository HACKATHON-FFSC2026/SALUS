import '../repositories/sos_repository.dart';

class CancelSosUseCase {
  final ISosRepository _repository;

  CancelSosUseCase(this._repository);

  Future<void> execute(String alertId) async {
    await _repository.cancelSos(alertId);
  }
}