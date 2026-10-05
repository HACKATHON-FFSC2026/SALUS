import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/utils/geo_math.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/presentation/providers/area_name_provider.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/risks/presentation/mappers/zone_ui_mapper.dart';

/// Fiche d'une zone (sûre ou catastrophe), ouverte au clic sur son polygone,
/// son marker ou son annotation AR.
Future<void> showZoneBottomSheet(BuildContext context, Zone zone) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => ZoneBottomSheet(zone: zone),
  );
}

class ZoneBottomSheet extends ConsumerWidget {
  const ZoneBottomSheet({super.key, required this.zone});

  final Zone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSafe = zone.type == ZoneType.safe;
    final color = zone.borderColor;
    // Position de l'utilisateur : la « Position » est décrite en distance et
    // direction (pas de lat/long illisibles).
    final user = ref.watch(locationProvider.select((s) => s.position));
    // Quartier / ville du centre de la zone (geocoding inverse, mis en cache).
    final areaName = ref.watch(areaNameProvider(zone.center));
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      isSafe ? Icons.health_and_safety_outlined : zone.icon,
                      color: color,
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
                            isSafe ? 'Zone sûre' : 'Zone ${zone.label}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isSafe
                                ? 'Zone sécurisée à proximité'
                                : switch (zone.severity) {
                                  Severity.low => 'Gravité faible',
                                  Severity.medium => 'Gravité moyenne',
                                  Severity.high => 'Gravité élevée',
                                  Severity.critical => 'Gravité critique',
                                  null => 'Catastrophe',
                                },
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
              if (!isSafe) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NIVEAU DE RISQUE',
                        style: TextStyle(
                          color: AppColors.inactive,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 20, color: color),
                          const SizedBox(width: 8),
                          Text(
                            switch (zone.severity) {
                              Severity.low => 'Faible',
                              Severity.medium => 'Modéré',
                              Severity.high => 'Élevé',
                              Severity.critical => 'Critique',
                              null => 'Élevé',
                            },
                            style: TextStyle(
                              color: color,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'DESCRIPTION',
                style: TextStyle(
                  color: AppColors.inactive,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (zone.description == null || zone.description!.isEmpty)
                    ? 'Aucune description fournie pour cette zone.'
                    : zone.description!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'INFORMATIONS',
                style: TextStyle(
                  color: AppColors.inactive,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(height: 8),
              _Row(
                icon: Icons.category_outlined,
                label: 'Nature',
                value: zone.nature,
              ),
              _Row(
                icon: Icons.near_me_outlined,
                label: 'Lieu',
                value: areaName.when(
                  data: (name) => name ?? 'Lieu inconnu',
                  loading: () => 'Recherche du lieu…',
                  error: (_, _) => 'Lieu indisponible (hors ligne)',
                ),
              ),
              _Row(
                icon: Icons.straighten_outlined,
                label: 'Distance',
                value: _distanceLabel(user),
              ),
              _Row(
                icon: Icons.source_outlined,
                label: 'Source',
                value: zone.source,
              ),
              _Row(
                icon: Icons.schedule_outlined,
                label: 'Début',
                value: _formatDate(zone.startedAt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Distance/direction en clair : « à 850 m au nord-est de vous ».
  String _distanceLabel(GeoPoint? user) {
    if (zone.geometry.isEmpty || user == null) {
      return 'Localisation indisponible';
    }
    final center = GeoMath.centroid(zone.geometry);
    final from = firestore.GeoPoint(user.latitude, user.longitude);
    final km = GeoMath.distanceKm(from, center);
    final bearing = GeoMath.bearingDegrees(from, center);
    return 'à ${_formatDistance(km * 1000)} ${GeoMath.cardinalFr(bearing)} de vous';
  }

  String _formatDistance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label : ',
                style: const TextStyle(color: AppColors.inactive, fontSize: 14),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
