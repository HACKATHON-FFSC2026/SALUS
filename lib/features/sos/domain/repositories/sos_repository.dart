import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/entities/help_response_entity.dart';
import 'package:salus/core/entities/location_share_entity.dart';

abstract class ISosRepository {
  /// Émet un nouveau SOS et retourne son identifiant: sans lui, la victime ne
  /// peut pas suivre son alerte ni l'annuler.
  Future<String> sendSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  });

  /// Écoute les mises à jour en temps réel d'une alerte SOS spécifique.
  Stream<SOSAlert?> watchSosAlert(String alertId);

  /// « Je suis en sécurité » : la victime annule sa propre alerte.
  Future<void> cancelSos(String alertId);

  /// Liste des alertes actives, restreinte à [geoCells] quand elles sont
  /// connues (proximité). Sans cellules, la liste est globale et bornée.
  Stream<List<SOSAlert>> watchActiveSosAlerts({List<String>? geoCells});

  /// Mes alertes encore actives, tous types de détresse confondus.
  ///
  /// Permet de ne pas émettre une seconde alerte pour la même détresse après
  /// un redémarrage de l'application.
  Stream<List<SOSAlert>> watchMyActiveSosAlerts();

  /// Se déclare intervenant. Idempotent: un uid déjà présent ne change rien.
  Future<void> respondToSos(String alertId);

  /// Propose son aide sur une alerte et retourne l'identifiant du suivi.
  ///
  /// Complète [respondToSos] : le registre `responderIds` est figé, ce
  /// document porte l'état vivant de l'intervenant.
  Future<String> offerHelp({
    required String alertId,
    ResponseType responseType = ResponseType.comingInPerson,
    String? message,
  });

  /// Fait avancer son propre suivi : en route, arrivé, ou désisté.
  Future<void> setHelpStatus({
    required String responseId,
    required HelpResponseStatus status,
  });

  /// Suivis des intervenants sur une alerte, pour la victime.
  Stream<List<HelpResponse>> watchHelpResponses(String alertId);

  /// Position partagée par un intervenant pendant qu'il se déplace.
  ///
  /// Un document par intervenant et par alerte: deux intervenants sur la même
  /// alerte n'écrivent donc jamais le même document, ce qui évite les conflits
  /// d'écriture.
  Future<void> shareResponderLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  });

  /// Interrompt le partage de position d'un intervenant.
  Future<void> stopResponderLocation(String alertId);

  /// Positions des intervenants connues sur une alerte.
  Stream<List<LocationShare>> watchResponderLocations(String alertId);

  /// Partage la position courante de la victime pendant que l'alerte est active.
  Future<void> shareLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  });
}