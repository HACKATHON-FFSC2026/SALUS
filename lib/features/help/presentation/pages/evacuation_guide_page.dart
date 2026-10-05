import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/help/domain/entities/evacuation_guidelines.dart';

/// Mode évacuation hors connexion (spec §1.1 « Guide en cas d'urgence »,
/// MUST). Une page, un sélecteur, du texte statique : utilisable en panique,
/// sans réseau, depuis l'onglet AIDE ou le bandeau « zone à risque » de la
/// carte. [initialType] pré-sélectionne le type de catastrophe en cours.
@RoutePage()
class EvacuationGuidePage extends StatefulWidget {
  const EvacuationGuidePage({super.key, this.initialType});

  final DisasterType? initialType;

  @override
  State<EvacuationGuidePage> createState() => _EvacuationGuidePageState();
}

class _EvacuationGuidePageState extends State<EvacuationGuidePage> {
  DisasterType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final guideline = _selected == null
        ? null
        : EvacuationGuides.forType(_selected!);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Mode évacuation',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final type in EvacuationGuides.orderedTypes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_labelOf(type)),
                      selected: _selected == type,
                      selectedColor: AppColors.secondary.withValues(alpha: 0.85),
                      labelStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _selected = type),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (guideline == null)
            const _PickPrompt()
          else
            _GuidelineBody(guideline: guideline),
        ],
      ),
    );
  }

  static String _labelOf(DisasterType type) => switch (type) {
        DisasterType.earthquake => 'Séisme',
        DisasterType.flood => 'Inondation',
        DisasterType.cyclone => 'Cyclone',
        DisasterType.tsunami => 'Tsunami',
        DisasterType.landslide => 'Glissement',
        DisasterType.volcano => 'Volcan',
        _ => 'Général',
      };
}

class _PickPrompt extends StatelessWidget {
  const _PickPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inactive.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'Choisissez le type de catastrophe en cours. Depuis la carte, le '
        'bandeau « zone à risque » ouvre directement le bon mode.',
        style: TextStyle(color: AppColors.inactive, fontSize: 13, height: 1.4),
      ),
    );
  }
}

class _GuidelineBody extends StatelessWidget {
  const _GuidelineBody({required this.guideline});

  final EvacuationGuideline guideline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guideline.title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final step in guideline.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.directions_run,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
