import 'package:salus/core/entities/sos_alert_entity.dart';

abstract class ISosRepository {
  /// Émet un nouveau SOS avec la géolocalisation et le type de détresse
  Future<void> sendSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  });

  /// Écoute les mises à jour en temps réel d'une alerte SOS spécifique
  Stream<SOSAlert?> watchSosAlert(String alertId);

  /// Tâche 13 : Annuler une alerte SOS active
  Future<void> cancelSos(String alertId);

  /// Tâche 14 : Écouter la liste de toutes les alertes SOS actives à proximité
  Stream<List<SOSAlert>> watchActiveSosAlerts();

  /// Tâche 14 & 15 : Répondre à un SOS et incrémenter le nombre d'intervenants
  Future<void> respondToSos(String alertId);
}