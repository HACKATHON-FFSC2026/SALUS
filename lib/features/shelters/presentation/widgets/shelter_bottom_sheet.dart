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
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
Future<void> showShelterDetailSheet(
  BuildContext context,
  Shelter shelter, {
  VoidCallback? onStartRoute,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ShelterDetailSheet(shelter: shelter, onStartRoute: onStartRoute),
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
  const ShelterDetailSheet({
    super.key,
    required this.shelter,
    this.onStartRoute,
  });

  final Shelter shelter;
  final VoidCallback? onStartRoute;

  @override
  Widget build(BuildContext context) {
    final available = shelter.availablePlaces;
    final progress = shelter.capacityTotal == 0
        ? 0.0
        : available / shelter.capacityTotal;
    final canNavigate = shelter.canStartNavigation && onStartRoute != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: shelter.availabilityColor.withValues(
                alpha: 0.12,
              ),
              child: Icon(
                Icons.home_work_outlined,
                color: shelter.availabilityColor,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelter.name,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      shelter.address,
                      style: const TextStyle(
                        color: AppColors.inactive,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Fermer',
              icon: const Icon(Icons.close, color: AppColors.inactive),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: shelter.availabilityBackgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Disponibilité',
                    style: TextStyle(
                      color: AppColors.inactive,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ShelterStatusChip(status: shelter.status),
                  ShelterValidationChip(status: shelter.validationStatus),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$available',
                    style: TextStyle(
                      color: shelter.availabilityColor,
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 2),
                    child: Text(
                      'disponibles sur ${shelter.capacityTotal}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 7,
                  color: shelter.availabilityColor,
                  backgroundColor: Colors.white.withValues(alpha: .8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ÉQUIPEMENTS',
          style: TextStyle(
            color: AppColors.inactive,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 10),
        ShelterResourcesWrap(resources: shelter.resources),
        if (onStartRoute != null) ...[
          const SizedBox(height: 20),
          if (canNavigate)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStartRoute,
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Démarrer l’itinéraire'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            )
          else
            Text(
              shelter.validationStatus != ValidationStatus.validated
                  ? 'Itinéraire disponible après validation du refuge.'
                  : 'Ce refuge ne dispose pas actuellement de places ouvertes.',
              style: const TextStyle(color: AppColors.inactive, fontSize: 12),
            ),
        ],
      ],
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
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
