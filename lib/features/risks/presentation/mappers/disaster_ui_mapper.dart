import 'package:flutter/material.dart';
import 'package:salus/core/entities/zone_entity.dart';
 
/// Source unique pour l'apparence d'un type de catastrophe : réutilisée par les
/// marqueurs de la carte ET par les cartes d'alerte.
extension DisasterTypeUi on DisasterType? {
  String get label => switch (this) {
        DisasterType.earthquake => 'Séisme',
        DisasterType.tsunami => 'Tsunami',
        DisasterType.cyclone => 'Cyclone',
        DisasterType.flood => 'Inondation',
        DisasterType.landslide => 'Glissement de terrain',
        DisasterType.volcano => 'Volcan',
        _ => 'Catastrophe',
      };
 
  IconData get icon => switch (this) {
        DisasterType.earthquake => Icons.warning_amber_rounded, // pas d'icône séisme dans cette version de Flutter
        DisasterType.tsunami => Icons.tsunami,
        DisasterType.cyclone => Icons.cyclone,
        DisasterType.flood => Icons.flood,
        DisasterType.landslide => Icons.landslide,
        DisasterType.volcano => Icons.volcano,
        _ => Icons.warning_amber_rounded,
      };
}
 
extension SeverityUi on Severity? {
  Color get color => switch (this) {
        Severity.low => Colors.yellow.shade700,
        Severity.medium => Colors.orange,
        Severity.high => Colors.red,
        Severity.critical => Colors.purple,
        null => Colors.red,
      };
}