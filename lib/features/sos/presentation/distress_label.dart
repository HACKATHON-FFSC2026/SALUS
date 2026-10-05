import 'package:salus/core/entities/sos_alert_entity.dart';

/// Libellé français d'un type de détresse, et niveau d'urgence associé.
///
/// Partagé par la liste des SOS et la fiche d'intervention : cette dernière
/// affichait l'énum anglais (`MEDICAL`, `SECURITY`), les seuls mots anglais de
/// l'interface.
extension DistressTypeLabel on DistressType {
  String get label => switch (this) {
    DistressType.medical => 'Médical',
    DistressType.security => 'Agression',
    DistressType.accident => 'Accident',
    DistressType.fire => 'Incendie',
    DistressType.other => 'Autre',
  };

  /// Urgence vitale immédiate. Sert à colorer la pastille : incendie et
  /// accident ne sont pas du même calibre qu'« autre », sans pour autant être
  /// au niveau médical/agression.
  bool get isCritical =>
      this == DistressType.medical || this == DistressType.security;
}
