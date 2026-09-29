import 'package:flutter/material.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';

/// Présentation d'un [ShelterStatus] (libellé, couleur, icône), partagée par
/// les markers de la carte et la fiche refuge.
///
/// `ShelterStatus` n'est pas modifié : on l'enrichit uniquement côté UI.
extension ShelterStatusUi on ShelterStatus {
  String get label => switch (this) {
    ShelterStatus.open => 'Ouvert',
    ShelterStatus.almostFull => 'Presque complet',
    ShelterStatus.full => 'Complet',
    ShelterStatus.closed => 'Fermé',
  };

  Color get color => switch (this) {
    ShelterStatus.open => const Color(0xFF2E7D32),
    ShelterStatus.almostFull => const Color(0xFFEF6C00),
    ShelterStatus.full => const Color(0xFFC62828),
    ShelterStatus.closed => AppColors.inactive,
  };

  IconData get icon => switch (this) {
    ShelterStatus.open => Icons.check_circle_outline,
    ShelterStatus.almostFull => Icons.error_outline,
    ShelterStatus.full => Icons.block,
    ShelterStatus.closed => Icons.do_not_disturb_on_outlined,
  };
}

/// Pastille « statut » réutilisable (fiche refuge).
class ShelterStatusChip extends StatelessWidget {
  const ShelterStatusChip({super.key, required this.status});

  final ShelterStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
