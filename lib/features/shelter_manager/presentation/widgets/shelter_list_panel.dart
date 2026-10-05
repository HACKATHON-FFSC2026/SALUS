import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/shelter_manager/domain/shelter_rules.dart';
import 'package:salus/features/shelter_manager/presentation/shelter_ui.dart';
import 'package:salus/core/entities/shelter_entity.dart';


/// Liste « Mes refuges » : panneau gauche en large, page d'accueil en étroit.
class ShelterListPanel extends StatelessWidget {
  const ShelterListPanel({
    super.key,
    required this.shelters,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
    this.showCreateButton = false,
  });

  final List<Shelter> shelters;
  final String? selectedId;
  final ValueChanged<Shelter> onSelect;
  final VoidCallback onCreate;
  final bool showCreateButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mes refuges (${shelters.length})',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (showCreateButton && shelters.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer'),
                ),
            ],
          ),
        ),
        Expanded(
          child: shelters.isEmpty
              ? _EmptyState(onCreate: onCreate)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: shelters.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ShelterTile(
                    shelter: shelters[i],
                    selected: shelters[i].id == selectedId,
                    onTap: () => onSelect(shelters[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ShelterTile extends StatelessWidget {
  const _ShelterTile({
    required this.shelter,
    required this.selected,
    required this.onTap,
  });

  final Shelter shelter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = shelter.status;
    return AppCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shelter.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: status.label, icon: status.icon, color: status.color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            shelter.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inactive, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: shelter.fillRate,
              minHeight: 8,
              color: status.color,
              backgroundColor: status.color.withValues(alpha: .15),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${shelter.capacityOccupied} / ${shelter.capacityTotal} personnes',
            style: const TextStyle(fontSize: 12, color: AppColors.inactive),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_work_outlined,
                  size: 64, color: AppColors.inactive),
              const SizedBox(height: 16),
              const Text(
                'Aucun refuge pour le moment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crée ton premier refuge pour suivre son occupation et son '
                'statut en temps réel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inactive),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Créer mon premier refuge'),
              ),
            ],
          ),
        ),
      );
}
