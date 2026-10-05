import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Alertes catastrophe')),
      body: ref
          .watch(activeRiskZonesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: AppColors.inactive,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Impossible de charger les alertes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inactive),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(activeRiskZonesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
            data: (zones) {
              if (zones.isEmpty) {
                return const Center(
                  child: Text('Aucune alerte active pour le moment.'),
                );
              }
              // Les plus graves d'abord, puis les plus récentes: sans tri,
              // l'ordre du flux plaçait une alerte faible avant une critique.
              final sorted = [...zones]..sort((a, b) {
                final bySeverity = (b.severity?.index ?? -1).compareTo(
                  a.severity?.index ?? -1,
                );
                if (bySeverity != 0) return bySeverity;
                return b.startedAt.compareTo(a.startedAt);
              });
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _DisasterAlertCard(sorted[index]),
              );
            },
          ),
  );
}

class _DisasterAlertCard extends StatelessWidget {
  const _DisasterAlertCard(this.zone);

  final Zone zone;

  String get _disaster => switch (zone.disasterType?.name) {
    'flood' => 'Inondation',
    'cyclone' => 'Cyclone',
    'landslide' => 'Glissement de terrain',
    'earthquake' => 'Séisme',
    'tsunami' => 'Tsunami',
    'volcano' => 'Éruption volcanique',
    _ => 'Alerte de risque',
  };

  String get _severity => switch (zone.severity?.name) {
    'low' => 'Faible',
    'medium' => 'Modérée',
    'high' => 'Élevée',
    'critical' => 'Critique',
    _ => 'Non précisée',
  };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(zone.severity);
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.source,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$_disaster · Gravité $_severity'),
                  if (zone.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(zone.description!),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 13,
                        color: AppColors.inactive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _alertDate(zone.startedAt),
                        style: const TextStyle(
                          color: AppColors.inactive,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          zone.origin.name == 'manual'
                              ? 'Publiée par une organisation'
                              : 'Détection automatique',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inactive,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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

/// Couleurs de gravité, alignées sur celles des zones de la carte.
Color _severityColor(Severity? severity) => switch (severity) {
  Severity.low => const Color(0xffe9a23b),
  Severity.medium => const Color(0xffe47736),
  Severity.high => const Color(0xffc94b4b),
  Severity.critical => const Color(0xff8f2020),
  null => AppColors.sos,
};

String _alertDate(DateTime start) =>
    '${start.day.toString().padLeft(2, '0')}/'
    '${start.month.toString().padLeft(2, '0')} '
    '${start.hour.toString().padLeft(2, '0')}:'
    '${start.minute.toString().padLeft(2, '0')}';
