import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/shelter_manager/presentation/providers/shelter_manager_providers.dart';
import 'package:salus/features/shelter_manager/presentation/shelter_ui.dart';
import 'package:salus/features/shelter_manager/presentation/widgets/occupancy_card.dart';
import 'package:salus/core/entities/shelter_entity.dart';


/// Données d'un refuge + actions temps réel. Ne garde aucun état local :
/// tout vient du flux Firestore (relu par id, donc toujours à jour).
class ShelterDetailPanel extends ConsumerWidget {
  const ShelterDetailPanel({super.key, required this.shelterId});
  final String shelterId;

  /// « Presque complet » est calculé, pas choisi.
  static const _manual = [
    ShelterStatus.open,
    ShelterStatus.full,
    ShelterStatus.closed,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelters = ref.watch(managedSheltersProvider).value ?? const [];
    final shelter = shelters.where((s) => s.id == shelterId).firstOrNull;
    if (shelter == null) {
      return const Center(child: Text('Refuge introuvable'));
    }

    final actions = ref.read(shelterActionsProvider.notifier);
    final status = shelter.status;
    final validation = shelter.validationStatus;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              shelter.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(shelter.address,
                style: const TextStyle(color: AppColors.inactive)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(label: status.label, icon: status.icon, color: status.color),
                StatusChip(
                  label: validation.label,
                  icon: validation.icon,
                  color: validation.color,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mis à jour ${timeAgo(shelter.updatedAt)}',
              style: const TextStyle(color: AppColors.inactive, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OccupancyCard(
              shelter: shelter,
              onAdjust: (d) => actions.adjustOccupancy(shelter, d),
            ),
            const SizedBox(height: 16),
            _section('Statut du refuge'),
            SegmentedButton<ShelterStatus>(
              showSelectedIcon: false,
              segments: [
                for (final s in _manual)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {
                status == ShelterStatus.almostFull ? ShelterStatus.open : status,
              },
              onSelectionChanged: (sel) => actions.setStatus(shelter, sel.first),
              style: SegmentedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                selectedBackgroundColor: status.color.withValues(alpha: .18),
                selectedForegroundColor: status.color,
              ),
            ),
            if (status == ShelterStatus.almostFull)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Presque complet : statut automatique (≥ 80 % d’occupation).',
                  style: TextStyle(color: AppColors.inactive, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            _section('Ressources disponibles'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _resource('Eau potable', Icons.water_drop_outlined,
                      shelter.resources.water,
                      (v) => actions.setResources(shelter, shelter.resources.copyWith(water: v))),
                  const Divider(height: 1),
                  _resource('Nourriture', Icons.restaurant_outlined,
                      shelter.resources.food,
                      (v) => actions.setResources(shelter, shelter.resources.copyWith(food: v))),
                  const Divider(height: 1),
                  _resource('Électricité', Icons.bolt_outlined,
                      shelter.resources.electricity,
                      (v) => actions.setResources(shelter, shelter.resources.copyWith(electricity: v))),
                  const Divider(height: 1),
                  _resource('Trousse médicale', Icons.medical_services_outlined,
                      shelter.resources.medicalKit,
                      (v) => actions.setResources(shelter, shelter.resources.copyWith(medicalKit: v))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section('Informations'),
            AppCard(
              child: Column(
                children: [
                  _info('Capacité totale', '${shelter.capacityTotal} personnes'),
                  const SizedBox(height: 8),
                  _info(
                    'Position',
                    '${shelter.location.latitude.toStringAsFixed(5)}, '
                        '${shelter.location.longitude.toStringAsFixed(5)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );

  Widget _resource(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(
          value ? 'Disponible' : 'Indisponible',
          style: const TextStyle(color: AppColors.inactive, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
      );

  Widget _info(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.inactive)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
