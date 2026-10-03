import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/map/presentation/widgets/salus_map_widget.dart';

class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(activeRiskZonesProvider);
    final hasActiveAlerts = alerts.asData?.value.isNotEmpty == true;
    final alertText = alerts.when(
      loading: () => 'Chargement des alertes…',
      error: (_, _) => 'Alertes momentanément indisponibles',
      data: (zones) => zones.isEmpty
          ? 'Aucune alerte active'
          : '${zones.length} alerte${zones.length == 1 ? '' : 's'} active${zones.length == 1 ? '' : 's'}',
    );
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SalusMapWidget()),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Card(
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
                      hasActiveAlerts
                          ? Icons.warning_amber_rounded
                          : Icons.shield_outlined,
                      color: hasActiveAlerts
                          ? Theme.of(context).colorScheme.error
                          : AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      alertText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
