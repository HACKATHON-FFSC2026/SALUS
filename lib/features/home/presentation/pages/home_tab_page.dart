import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/map/presentation/widgets/salus_map_widget.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/risks/presentation/mappers/zone_ui_mapper.dart';
import 'package:salus/features/sos/presentation/providers/active_sos_provider.dart';

class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAsync = ref.watch(activeSosStreamProvider);
    final firestoreZonesAsync = ref.watch(activeRiskZonesProvider);
    final externalZonesAsync = ref.watch(riskZonesProvider);
    final location = ref.watch(locationProvider).position;
    final geofence = ref.watch(geofenceServiceProvider);
    final zonesById = <String, Zone>{
      for (final zone in externalZonesAsync.value ?? const <Zone>[])
        if (zone.isActive && zone.type == ZoneType.risk) zone.id: zone,
      for (final zone in firestoreZonesAsync.value ?? const <Zone>[])
        if (zone.isActive && zone.type == ZoneType.risk) zone.id: zone,
    };
    final hasZoneData =
        externalZonesAsync.hasValue || firestoreZonesAsync.hasValue;
    final dangerZones = location == null
        ? const <Zone>[]
        : zonesById.values
              .where(
                (zone) =>
                    zone.geometry.length >= 3 &&
                    geofence.isUserInZone(
                      firestore.GeoPoint(location.latitude, location.longitude),
                      zone,
                    ),
              )
              .toList(growable: false);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SalusMapWidget()),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 76,
            child: _SituationBanner(
              sosCount: _count(sosAsync),
              riskCount: hasZoneData ? zonesById.length : null,
              sosUnavailable: sosAsync.hasError,
              riskUnavailable:
                  !hasZoneData &&
                  externalZonesAsync.hasError &&
                  firestoreZonesAsync.hasError,
              dangerZones: dangerZones,
            ),
          ),
        ],
      ),
    );
  }

  static int? _count(AsyncValue<List<SOSAlert>> value) =>
      value.maybeWhen(data: (alerts) => alerts.length, orElse: () => null);
}

class _SituationBanner extends StatelessWidget {
  const _SituationBanner({
    required this.sosCount,
    required this.riskCount,
    required this.sosUnavailable,
    required this.riskUnavailable,
    required this.dangerZones,
  });

  final int? sosCount;
  final int? riskCount;
  final bool sosUnavailable;
  final bool riskUnavailable;
  final List<Zone> dangerZones;

  @override
  Widget build(BuildContext context) {
    final hasRisk = (riskCount ?? 0) > 0;
    final hasSos = (sosCount ?? 0) > 0;
    final icon = hasRisk
        ? Icons.warning_amber_rounded
        : hasSos
        ? Icons.emergency_share_outlined
        : Icons.shield_outlined;
    final title = switch (sosCount) {
      null when sosUnavailable => 'SOS actifs indisponibles',
      null => 'SOS actifs en cours de chargement…',
      0 => 'Aucun SOS actif',
      final count => '$count SOS actif${count == 1 ? '' : 's'}',
    };
    final subtitle = switch (riskCount) {
      null when riskUnavailable => 'Alertes catastrophe indisponibles',
      null => 'Alertes catastrophe en cours de chargement',
      0 => 'Aucune alerte catastrophe active',
      final count =>
        '$count alerte${count == 1 ? '' : 's'} catastrophe active${count == 1 ? '' : 's'}',
    };

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.97),
      elevation: 3,
      shadowColor: AppColors.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => context.router.push(const ActiveSosListRoute()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: hasRisk
                        ? Theme.of(context).colorScheme.error
                        : AppColors.primary,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.inactive),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.inactive,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (dangerZones.isNotEmpty) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () => context.router.push(
                EvacuationGuideRoute(
                  initialType: _worstDangerType(dangerZones),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 9, 10, 9),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.sos,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Vous êtes en zone à risque · ${dangerZones.first.label}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.sos,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.directions_run,
                      color: AppColors.sos,
                      size: 19,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Évacuer',
                      style: TextStyle(
                        color: AppColors.sos,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  DisasterType? _worstDangerType(List<Zone> zones) {
    DisasterType? worst;
    var worstIndex = -1;
    for (final zone in zones) {
      final type = zone.disasterType;
      if (type == null) continue;
      final index = zone.severity?.index ?? -1;
      if (index > worstIndex) {
        worstIndex = index;
        worst = type;
      }
    }
    return worst;
  }
}
