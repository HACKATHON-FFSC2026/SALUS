import 'package:flutter/material.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/features/risks/presentation/mappers/zone_ui_mapper.dart';
 
/// Marqueur posé au centre d'une zone à risque : l'icône indique le TYPE de
/// catastrophe, la couleur indique la GRAVITÉ (comme le cercle en arrière-plan).
class DisasterMarkerPin extends StatelessWidget {
  const DisasterMarkerPin({super.key, required this.zone});
 
  final Zone zone;
 
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: zone.label,
      child: Container(
        decoration: BoxDecoration(
          color: zone.borderColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
        ),
        alignment: Alignment.center,
        child: Icon(zone.icon, color: Colors.white, size: 22),
      ),
    );
  }
}
 