import 'package:salus/features/sos/domain/entities/help_response.dart';
import 'package:salus/features/sos/domain/repositories/sos_repository.dart';

/// Se propose comme intervenant sur une alerte.
///
/// Fait les deux écritures qu'exige le modèle : l'ajout au registre
/// `responderIds` de l'alerte, puis le document de suivi qui portera l'état
/// vivant. L'ordre compte — le registre d'abord, parce que les règles
/// n'autorisent l'accès aux suivis que si l'on figure dans `responderIds`.
class OfferHelpUseCase {
  OfferHelpUseCase(this._repository);

  final ISosRepository _repository;

  /// Retourne l'identifiant du suivi, nécessaire pour le faire avancer ou se
  /// rétracter ensuite.
  Future<String> execute({
    required String alertId,
    HelpResponseType responseType = HelpResponseType.comingInPerson,
    String? message,
  }) async {
    if (alertId.isEmpty) return '';
    await _repository.respondToSos(alertId);
    return _repository.offerHelp(
      alertId: alertId,
      responseType: responseType,
      message: message,
    );
  }
}

/// Fait avancer son propre suivi : en route, arrivé, ou désisté.
class SetHelpStatusUseCase {
  SetHelpStatusUseCase(this._repository);

  final ISosRepository _repository;

  Future<void> execute({
    required String responseId,
    required HelpResponseStatus status,
  }) {
    if (responseId.isEmpty) return Future<void>.value();
    return _repository.setHelpStatus(responseId: responseId, status: status);
  }
}