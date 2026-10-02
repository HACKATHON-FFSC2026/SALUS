import 'package:cloud_firestore/cloud_firestore.dart';

/// Position d'un intervenant, partagée pendant qu'il se porte au secours.
///
/// Modélise un document de `location_shares`, la collection que les règles
/// Firestore prévoient déjà pour le suivi rapproché d'une intervention.
class ResponderLocation {
  const ResponderLocation({
    required this.userId,
    required this.sosAlertId,
    required this.latitude,
    required this.longitude,
    this.updatedAt,
    this.isActive = true,
  });

  final String userId;
  final String sosAlertId;
  final double latitude;
  final double longitude;
  final DateTime? updatedAt;

  /// Faux quand l'intervenant a arrêté de partager: sa dernière position
  /// reste connue mais n'est plus un point vivant sur la carte.
  final bool isActive;

  GeoPoint get point => GeoPoint(latitude, longitude);

  /// Une position périmée n'est plus une position: on ne l'affiche pas comme
  /// telle, sinon l'intervenant semble arrêté au milieu de nulle part.
  bool get isStale {
    final at = updatedAt;
    if (at == null) return true;
    return DateTime.now().difference(at) > const Duration(minutes: 5);
  }

  factory ResponderLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('Position sans données');
    }
    final raw = json['currentLocation'];
    if (raw is! GeoPoint) {
      throw const FormatException('Position sans coordonnées exploitables');
    }
    return ResponderLocation(
      userId: (json['userId'] as String?) ?? '',
      sosAlertId: (json['sosAlertId'] as String?) ?? '',
      latitude: raw.latitude,
      longitude: raw.longitude,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sosAlertId': sosAlertId,
      'currentLocation': point,
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };
  }

  /// Identifiant déterministe: un intervenant sur une alerte donnée n'a
  /// qu'un document, donc rien ne s'accumule si le flux repart.
  static String documentIdFor({
    required String alertId,
    required String userId,
  }) => '${alertId}_$userId';
}