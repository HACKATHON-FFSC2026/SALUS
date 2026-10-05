import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/shelter_manager/domain/shelter_rules.dart';
import 'package:salus/features/shelter_manager/presentation/shelter_ui.dart';
import 'package:salus/core/entities/shelter_entity.dart';


/// Compteur d'occupation : cibles tactiles larges (une main, stress, gants),
/// retour haptique, progression + texte (pas que la couleur).
class OccupancyCard extends StatelessWidget {
  const OccupancyCard({
    super.key,
    required this.shelter,
    required this.onAdjust,
  });

  final Shelter shelter;
  final void Function(int delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    final color = shelter.status.color;
    final canRemove = shelter.capacityOccupied > 0;
    final canAdd = shelter.capacityOccupied < shelter.capacityTotal;

    void tap(int delta) {
      HapticFeedback.selectionClick();
      onAdjust(delta);
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Personnes accueillies',
            style: TextStyle(color: AppColors.inactive, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            label:
                '${shelter.capacityOccupied} sur ${shelter.capacityTotal} places occupées',
            child: Text(
              '${shelter.capacityOccupied} / ${shelter.capacityTotal}',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: shelter.fillRate,
              minHeight: 12,
              color: color,
              backgroundColor: color.withValues(alpha: .15),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${shelter.available} places disponibles',
            style: const TextStyle(color: AppColors.inactive),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StepButton(
                  icon: Icons.remove,
                  tooltip: 'Retirer une personne (appui long : 5)',
                  onTap: canRemove ? () => tap(-1) : null,
                  onLongPress: canRemove ? () => tap(-5) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StepButton(
                  icon: Icons.add,
                  tooltip: 'Ajouter une personne (appui long : 5)',
                  onTap: canAdd ? () => tap(1) : null,
                  onLongPress: canAdd ? () => tap(5) : null,
                  primary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Appui long : ±5',
            style: TextStyle(color: AppColors.inactive, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.onLongPress,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(64)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    final child = Icon(icon, size: 32);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: primary
            ? ElevatedButton(onPressed: onTap, style: style, child: child)
            : OutlinedButton(onPressed: onTap, style: style, child: child),
      ),
    );
  }
}
