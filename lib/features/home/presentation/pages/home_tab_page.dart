import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/map/presentation/widgets/salus_map_widget.dart';
import 'package:salus/features/sos/presentation/providers/active_sos_provider.dart';

class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAsync = ref.watch(activeSosStreamProvider);
    final zonesAsync = ref.watch(activeRiskZonesProvider);
    final zones = zonesAsync.asData?.value ?? const [];
    final zoneText = zonesAsync.when(
      loading: () => 'Chargement des alertes…',
      error: (_, _) => 'Alertes momentanément indisponibles',
      data: (items) => items.isEmpty
          ? 'Aucune alerte catastrophe active'
          : '${items.length} alerte${items.length == 1 ? '' : 's'} catastrophe active${items.length == 1 ? '' : 's'}',
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SalusMapWidget()),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NearbyAlertsBanner(count: _count(sosAsync)),
                const SizedBox(height: 8),
                Card(
                  color: AppColors.surface.withValues(alpha: 0.96),
                  elevation: 3,
                  shadowColor: AppColors.primary.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          zones.isNotEmpty
                              ? Icons.warning_amber_rounded
                              : Icons.shield_outlined,
                          color: zones.isNotEmpty
                              ? Theme.of(context).colorScheme.error
                              : AppColors.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            zoneText,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
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

  /// Null means the stream is loading or unavailable.
  static int? _count(AsyncValue<List<SOSAlert>> sosAsync) =>
      sosAsync.maybeWhen(data: (alerts) => alerts.length, orElse: () => null);
}

class _NearbyAlertsBanner extends StatelessWidget {
  const _NearbyAlertsBanner({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (count) {
      null => (Icons.help_outline, 'Chargement des SOS actifs…'),
      0 => (Icons.check_circle_outline, 'Aucun SOS actif à proximité'),
      final n => (
        Icons.emergency_share_outlined,
        '$n SOS actif${n > 1 ? 's' : ''} à proximité',
      ),
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
              Icon(icon, color: AppColors.primary, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.inactive,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
