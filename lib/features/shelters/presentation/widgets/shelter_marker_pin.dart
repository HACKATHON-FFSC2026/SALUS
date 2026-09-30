import 'package:flutter/material.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';

/// Pin d'un refuge sur la carte.
///
/// La couleur et l'icône reprennent le [ShelterStatus] du refuge pour distinguer
/// les statuts d'un coup d'œil (ouvert, presque complet, complet, fermé).
class ShelterMarkerPin extends StatelessWidget {
  const ShelterMarkerPin({super.key, required this.status});

  final ShelterStatus status;

  /// Taille visible du pin (le [Marker] qui l'accueille est plus large pour
  /// garder une zone de tap confortable).
  static const double size = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Refuge ${status.label}',
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: status.color,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            status.icon,
            color: status.foregroundColor == status.color
                ? Colors.white
                : status.foregroundColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}
