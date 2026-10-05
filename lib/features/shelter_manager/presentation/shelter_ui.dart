import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/entities/shelter_entity.dart';


/// Libellés, icônes et couleurs. Jamais la couleur seule : toujours
/// couplée à une icône et un texte (accessibilité).
extension ShelterStatusUi on ShelterStatus {
  String get label => switch (this) {
        ShelterStatus.open => 'Ouvert',
        ShelterStatus.almostFull => 'Presque complet',
        ShelterStatus.full => 'Complet',
        ShelterStatus.closed => 'Fermé',
      };

  IconData get icon => switch (this) {
        ShelterStatus.open => Icons.check_circle_outline,
        ShelterStatus.almostFull => Icons.warning_amber_rounded,
        ShelterStatus.full => Icons.group_off_outlined,
        ShelterStatus.closed => Icons.block,
      };

  Color get color => switch (this) {
        ShelterStatus.open => AppColors.secondary,
        ShelterStatus.almostFull => const Color(0xFFD97706),
        ShelterStatus.full => const Color(0xFFC94B4B),
        ShelterStatus.closed => AppColors.inactive,
      };
}

extension ValidationStatusUi on ValidationStatus {
  String get label => switch (this) {
        ValidationStatus.pending => 'En attente de validation',
        ValidationStatus.validated => 'Validé',
        ValidationStatus.rejected => 'Refusé',
      };

  IconData get icon => switch (this) {
        ValidationStatus.pending => Icons.hourglass_top,
        ValidationStatus.validated => Icons.verified_outlined,
        ValidationStatus.rejected => Icons.cancel_outlined,
      };

  Color get color => switch (this) {
        ValidationStatus.pending => const Color(0xFFD97706),
        ValidationStatus.validated => AppColors.secondary,
        ValidationStatus.rejected => const Color(0xFFC94B4B),
      };
}

String timeAgo(DateTime date) {
  final d = DateTime.now().difference(date);
  if (d.inSeconds < 60) return 'à l’instant';
  if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
  if (d.inHours < 24) return 'il y a ${d.inHours} h';
  return 'il y a ${d.inDays} j';
}

/// Carte blanche arrondie, même style que les cartes du portail.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
}
