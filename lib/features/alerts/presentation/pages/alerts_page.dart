import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/alerts/domain/entities/disaster_alert.dart';
import 'package:salus/features/alerts/presentation/providers/alert_provider.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final readIds = ref.watch(readAlertIdsProvider);
    final readIdSet = readIds.value ?? const <String>{};
    ref.listen<AsyncValue<Set<String>>>(readAlertIdsProvider, (_, next) {
      if (!next.hasError) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de charger les alertes lues : ${next.error}'),
        ),
      );
    });
    final position = ref.watch(locationProvider.select((s) => s.position));
    final locationStatus = ref.watch(
      locationProvider.select((s) => s.status),
    );
    final externalZones = ref.watch(riskZonesProvider);
    final firestoreZones = ref.watch(activeRiskZonesProvider);
    final hasZones =
        externalZones.hasValue || firestoreZones.hasValue;
    final zonesUnavailable =
        !hasZones && externalZones.hasError && firestoreZones.hasError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes près de vous'),
        actions: [
          if (alerts.any((alert) => !readIdSet.contains(alert.id)))
            TextButton(
              onPressed: () => _markAllRead(context, ref),
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: !hasZones && !zonesUnavailable
          ? const Center(child: CircularProgressIndicator())
          : zonesUnavailable
          ? _Message(
              message: 'Impossible de charger les alertes pour le moment.',
              action: TextButton(
                onPressed: () {
                  ref.invalidate(riskZonesProvider);
                  ref.invalidate(activeRiskZonesProvider);
                },
                child: const Text('Réessayer'),
              ),
            )
          : position == null
          ? _Message(
              message: locationStatus == LocationStatus.loading
                  ? 'Recherche de votre position…'
                  : 'Activez la localisation pour afficher les alertes proches.',
              action: locationStatus == LocationStatus.loading
                  ? null
                  : TextButton(
                      onPressed: () =>
                          ref.read(locationProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
            )
          : alerts.isEmpty
          ? const _Message(
              message: 'Aucune alerte importante près de votre position.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _DisasterAlertCard(
                alert: alerts[index],
                isRead: readIdSet.contains(alerts[index].id),
                onMarkRead: () => _markRead(context, ref, alerts[index].id),
              ),
            ),
    );
  }

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(readAlertIdsProvider.notifier).markRead([id]);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’enregistrer la lecture : $error')),
      );
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(readAlertIdsProvider.notifier).markAllRead();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’enregistrer la lecture : $error')),
      );
    }
  }
}

class _DisasterAlertCard extends StatelessWidget {
  const _DisasterAlertCard({
    required this.alert,
    required this.isRead,
    required this.onMarkRead,
  });

  final DisasterAlert alert;
  final bool isRead;
  final VoidCallback onMarkRead;

  String get _severity => switch (alert.severity) {
    Severity.critical => 'Critique',
    Severity.high => 'Élevée',
    Severity.medium => 'Modérée',
    Severity.low => 'Faible',
    null => 'Non précisée',
  };

  String get _distance => alert.distanceKm < 1
      ? '${(alert.distanceKm * 1000).round()} m'
      : '${alert.distanceKm.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: alert.userInsideZone
            ? AppColors.sos
            : AppColors.inactive.withValues(alpha: 0.25),
        width: alert.userInsideZone ? 2 : 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alert.userInsideZone
                ? Icons.gpp_bad_outlined
                : Icons.warning_amber_rounded,
            color: AppColors.sos,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (!isRead)
                      const _AlertBadge(
                        label: 'NOUVEAU',
                        color: AppColors.secondary,
                      ),
                    if (alert.userInsideZone)
                      const _AlertBadge(label: 'DANS LA ZONE', color: AppColors.sos),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Gravité $_severity · à $_distance'),
                if (alert.approaching) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Le risque se rapproche de votre position.',
                    style: TextStyle(
                      color: AppColors.sos,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(alert.message),
                if (!isRead)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onMarkRead,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Marquer comme lue'),
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

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    ),
  );
}
