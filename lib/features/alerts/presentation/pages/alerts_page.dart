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
          error: (_, _) => const Center(
            child: Text('Impossible de charger les alertes pour le moment.'),
          ),
          data: (zones) => zones.isEmpty
              ? const Center(
                  child: Text('Aucune alerte active pour le moment.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: zones.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _DisasterAlertCard(zones[index]),
                ),
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.sos,
            size: 28,
          ),
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
                const SizedBox(height: 4),
                Text(
                  '${zone.geometry.length} points · ${zone.origin.name == 'manual' ? 'Alerte publiée par une organisation' : 'Détection automatique'}',
                  style: const TextStyle(
                    color: AppColors.inactive,
                    fontSize: 12,
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
