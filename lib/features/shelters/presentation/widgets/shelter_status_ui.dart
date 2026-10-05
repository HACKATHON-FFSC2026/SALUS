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
    ShelterStatus.almostFull => AppColors.secondary,
    ShelterStatus.full => const Color(0xFFC62828),
    ShelterStatus.closed => AppColors.inactive,
  };

  /// Texte et icône avec contraste suffisant sur un fond jaune.
  Color get foregroundColor =>
      this == ShelterStatus.almostFull ? AppColors.primary : color;

  IconData get icon => switch (this) {
    ShelterStatus.open => Icons.check_circle_outline,
    ShelterStatus.almostFull => Icons.error_outline,
    ShelterStatus.full => Icons.block,
    ShelterStatus.closed => Icons.do_not_disturb_on_outlined,
  };
}

/// Couleurs de disponibilité utilisées dans les listes et fiches refuge.
extension ShelterAvailabilityUi on Shelter {
  int get availablePlaces =>
      (capacityTotal - capacityOccupied).clamp(0, capacityTotal);

  /// Part des places occupées, 0..1. C'est ce que la barre de capacité doit
  /// montrer: une barre pleine = refuge plein. L'ancien calcul utilisait le
  /// ratio *disponible*, donc un refuge complet affichait une barre vide.
  double get occupancyRatio => capacityTotal == 0
      ? 0.0
      : (capacityOccupied / capacityTotal).clamp(0.0, 1.0);

  bool get canStartNavigation =>
      validationStatus == ValidationStatus.validated &&
      (status == ShelterStatus.open || status == ShelterStatus.almostFull) &&
      availablePlaces > 0;

  Color get availabilityColor {
    if (validationStatus == ValidationStatus.rejected ||
        status == ShelterStatus.closed ||
        status == ShelterStatus.full ||
        availablePlaces == 0) {
      return const Color(0xFFC62828);
    }
    if (status == ShelterStatus.almostFull ||
        availablePlaces / capacityTotal < 0.5) {
      return AppColors.secondary;
    }
    return const Color(0xFF2E7D32);
  }

  Color get availabilityBackgroundColor {
    if (availabilityColor == const Color(0xFFC62828)) {
      return const Color(0xFFFFF0EE);
    }
    if (status == ShelterStatus.almostFull ||
        (capacityTotal > 0 && availablePlaces / capacityTotal < 0.5)) {
      return const Color(0xFFFFF6E2);
    }
    return const Color(0xFFEDF6EE);
  }
}

/// Statut opérationnel en texte simple, pour éviter d'empiler les badges.
class ShelterStatusText extends StatelessWidget {
  const ShelterStatusText({super.key, required this.status});

  final ShelterStatus status;

  @override
  Widget build(BuildContext context) => Text(
    status.label,
    style: TextStyle(
      color: status.foregroundColor,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
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
          Icon(status.icon, size: 16, color: status.foregroundColor),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.foregroundColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de validation, distinct du statut d'occupation du refuge.
class ShelterValidationChip extends StatelessWidget {
  const ShelterValidationChip({
    super.key,
    required this.status,
    this.prominent = false,
  });

  final ValidationStatus status;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ValidationStatus.validated => (
        'Validé',
        const Color(0xFF2E7D32),
        Icons.verified_outlined,
      ),
      ValidationStatus.pending => (
        'En attente',
        AppColors.secondary,
        Icons.schedule,
      ),
      ValidationStatus.rejected => (
        'Rejeté',
        const Color(0xFFC62828),
        Icons.cancel_outlined,
      ),
    };
    final foreground = status == ValidationStatus.pending || !prominent
        ? AppColors.primary
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: prominent ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
