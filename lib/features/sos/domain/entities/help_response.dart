import 'package:cloud_firestore/cloud_firestore.dart';

/// Nature de l'aide proposée par un intervenant.
enum HelpResponseType {
  /// L'intervenant se déplace vers la victime.
  comingInPerson,

  /// Conseil texte, sans déplacement.
  textAdvice;
}

/// Suivi de l'intervenant sur une alerte.
///
/// `responderIds` sur l'alerte est un registre figé : les règles n'autorisent
/// que l'ajout, jamais le retrait, pour garder une trace de qui s est
/// proposé. Ce document porte donc l'état vivant — en route, arrivé, ou
/// désisté — qui est ce que la victime doit voir.
enum HelpResponseStatus {
  offered,
  enRoute,
  arrived,

  /// L'intervenant se rétracte. Sa position n'est plus partagée et il ne
  /// compte plus dans les gens sur place.
  cancelled;

  /// Compte comme intervenant en cours pour la victime.
  bool get isActive => this != HelpResponseStatus.cancelled;

  bool get isOnSite => this == HelpResponseStatus.arrived;
}

class HelpResponse {
  const HelpResponse({
    required this.id,
    required this.responderId,
    required this.sosAlertId,
    required this.responseType,
    required this.status,
    this.message,
    this.updatedAt,
  });

  final String id;
  final String responderId;
  final String sosAlertId;
  final HelpResponseType responseType;
  final HelpResponseStatus status;

  /// Consigne donnée à la victime pour le conseil texte.
  final String? message;

  final DateTime? updatedAt;

  bool get isActive => status.isActive;

  /// Un seul suivi par intervenant et par alerte: répondre deux fois à la même
  /// alerte réutilise le document au lieu d'en créer un second, qui
  /// doublerait le compte côté victime.
  static String documentIdFor({
    required String alertId,
    required String responderId,
  }) => '${alertId}_$responderId';

  HelpResponse copyWith({
    HelpResponseStatus? status,
    String? message,
    DateTime? updatedAt,
  }) {
    return HelpResponse(
      id: id,
      responderId: responderId,
      sosAlertId: sosAlertId,
      responseType: responseType,
      status: status ?? this.status,
      message: message ?? this.message,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory HelpResponse.fromJson(
    Map<String, dynamic>? json, {
    String? fallbackId,
  }) {
    if (json == null) {
      throw const FormatException('Réponse sans données');
    }
    return HelpResponse(
      id: (json['id'] as String?) ?? fallbackId ?? '',
      responderId: (json['responderId'] as String?) ?? '',
      sosAlertId: (json['sosAlertId'] as String?) ?? '',
      responseType: _enumByName(
        HelpResponseType.values,
        json['responseType'],
        HelpResponseType.comingInPerson,
      ),
      status: _enumByName(
        HelpResponseStatus.values,
        json['status'],
        HelpResponseStatus.offered,
      ),
      message: json['message'] as String?,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Le champ `status` est figé par les règles à `offered` à la création.
  Map<String, dynamic> toJson() {
    return {
      'responderId': responderId,
      'sosAlertId': sosAlertId,
      'responseType': responseType.name,
      'status': HelpResponseStatus.offered.name,
      'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}