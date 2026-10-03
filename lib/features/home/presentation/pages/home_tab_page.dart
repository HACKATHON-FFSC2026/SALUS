import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/map/presentation/widgets/salus_map_widget.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/sos/presentation/providers/active_sos_provider.dart';

class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAsync = ref.watch(activeSosStreamProvider);
    final firestoreZonesAsync = ref.watch(activeRiskZonesProvider);
    final externalZonesAsync = ref.watch(riskZonesProvider);
    final zonesById = <String, Zone>{
      for (final zone in externalZonesAsync.value ?? const <Zone>[])
        if (zone.isActive && zone.type == ZoneType.risk) zone.id: zone,
      for (final zone in firestoreZonesAsync.value ?? const <Zone>[])
        if (zone.isActive && zone.type == ZoneType.risk) zone.id: zone,
    };
    final hasZoneData =
        externalZonesAsync.hasValue || firestoreZonesAsync.hasValue;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SalusMapWidget()),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: _SituationBanner(
              sosCount: _count(sosAsync),
              riskCount: hasZoneData ? zonesById.length : null,
              sosUnavailable: sosAsync.hasError,
              riskUnavailable:
                  !hasZoneData &&
                  externalZonesAsync.hasError &&
                  firestoreZonesAsync.hasError,
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
  });

  final int? sosCount;
  final int? riskCount;
  final bool sosUnavailable;
  final bool riskUnavailable;

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
      color: AppColors.surface.withValues(alpha: 0.96),
      elevation: 3,
      shadowColor: AppColors.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.router.push(const ActiveSosListRoute()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(
                icon,
                color: hasRisk
                    ? Theme.of(context).colorScheme.error
                    : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inactive,
                      ),
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
    );
  }
}
