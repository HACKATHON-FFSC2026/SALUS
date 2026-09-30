import 'package:flutter/material.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';

/// Fiche courte d'un refuge, ouverte au clic sur son marker.
Future<void> showShelterBottomSheet(BuildContext context, Shelter shelter) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => ShelterBottomSheet(
      shelter: shelter,
      onSeeDetails: () {
        Navigator.of(sheetContext).pop();
        showShelterDetailSheet(context, shelter);
      },
    ),
  );
}

/// Fiche complète d'un refuge.
///
/// Aucune page détail n'existe dans le projet : on affiche ici les informations
/// déjà portées par l'Entity [Shelter], sans nouvelle navigation.
Future<void> showShelterDetailSheet(BuildContext context, Shelter shelter) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ShelterDetailSheet(shelter: shelter),
      ),
    ),
  );
}

/// Fiche courte : nom, adresse, capacité, statut et ressources activées.
class ShelterBottomSheet extends StatelessWidget {
  const ShelterBottomSheet({
    super.key,
    required this.shelter,
    this.onSeeDetails,
  });

  final Shelter shelter;
  final VoidCallback? onSeeDetails;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(title: shelter.name),
            const SizedBox(height: 4),
            _InfoLine(icon: Icons.place_outlined, text: shelter.address),
            const SizedBox(height: 10),
            ShelterStatusChip(status: shelter.status),
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.groups_outlined,
              text:
                  '${(shelter.capacityTotal - shelter.capacityOccupied).clamp(0, shelter.capacityTotal)} places disponibles',
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              'Ressources disponibles',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ShelterResourcesWrap(resources: shelter.resources),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onSeeDetails,
              child: const Text('Voir le refuge'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fiche complète du refuge (toutes les informations disponibles).
class ShelterDetailSheet extends StatelessWidget {
  const ShelterDetailSheet({super.key, required this.shelter});

  final Shelter shelter;

  @override
  Widget build(BuildContext context) {
    final location = shelter.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetTitle(title: shelter.name),
        const SizedBox(height: 8),
        ShelterStatusChip(status: shelter.status),
        const SizedBox(height: 16),
        _DetailRow(label: 'Adresse', value: shelter.address),
        _DetailRow(
          label: 'Capacité',
          value:
              '${shelter.capacityOccupied} / ${shelter.capacityTotal} '
              'personnes',
        ),
        _DetailRow(
          label: 'Localisation',
          value:
              '${location.latitude.toStringAsFixed(5)}, '
              '${location.longitude.toStringAsFixed(5)}',
        ),
        if (shelter.organizationId != null)
          _DetailRow(label: 'Organisation', value: shelter.organizationId!),
        _DetailRow(label: 'Créé le', value: _formatDate(shelter.createdAt)),
        _DetailRow(
          label: 'Mis à jour le',
          value: _formatDate(shelter.updatedAt),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ressources disponibles',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ShelterResourcesWrap(resources: shelter.resources),
      ],
    );
  }
}

/// Date lisible sans dépendance supplémentaire (`intl` n'est pas au projet).
String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

/// Ressources activées uniquement : les ressources désactivées ne sont pas
/// affichées.
class ShelterResourcesWrap extends StatelessWidget {
  const ShelterResourcesWrap({super.key, required this.resources});

  final ShelterResources resources;

  @override
  Widget build(BuildContext context) {
    // Mêmes libellés / icônes que le formulaire de création de refuge.
    final chips = <Widget>[
      if (resources.water)
        const _ResourceChip(icon: Icons.water_drop_outlined, label: 'Eau'),
      if (resources.food)
        const _ResourceChip(
          icon: Icons.restaurant_outlined,
          label: 'Nourriture',
        ),
      if (resources.electricity)
        const _ResourceChip(icon: Icons.bolt_outlined, label: 'Électricité'),
      if (resources.medicalKit)
        const _ResourceChip(
          icon: Icons.medical_services_outlined,
          label: 'Kit médical',
        ),
    ];

    if (chips.isEmpty) {
      return const Text(
        'Aucune ressource renseignée.',
        style: TextStyle(color: AppColors.inactive, fontSize: 13),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Fermer',
          icon: const Icon(Icons.close, color: AppColors.inactive),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.primary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.inactive, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
