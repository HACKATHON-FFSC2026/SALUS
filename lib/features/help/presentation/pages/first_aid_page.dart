import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/sos/domain/entities/first_aid_guidelines.dart';

/// Guide premiers secours hors connexion (spec §1.1 « Guide en cas d'urgence »).
/// Reprise des consignes écrites pour la fiche d'intervention
/// ([FirstAidGuideline]), sans aucun réseau.
@RoutePage()
class FirstAidPage extends StatelessWidget {
  const FirstAidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Premiers secours',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Consignes valables hors connexion. En danger immédiat, appuyez '
            'd\'abord sur le bouton SOS.',
            style: TextStyle(color: AppColors.inactive, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final type in DistressType.values)
            _GuidelineCard(guideline: FirstAidGuideline.getGuidelinesFor(type)),
        ],
      ),
    );
  }
}

class _GuidelineCard extends StatelessWidget {
  const _GuidelineCard({required this.guideline});

  final FirstAidGuideline guideline;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.inactive.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          title: Text(
            guideline.title,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          children: [
            for (final step in guideline.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.secondary,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
