import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import '../providers/active_sos_provider.dart';
import '../providers/responder_controller.dart';

@RoutePage()
class ActiveSosListPage extends ConsumerWidget {
  const ActiveSosListPage({super.key});

  static const _labels = {
    DistressType.medical: 'Médical',
    DistressType.security: 'Agression',
    DistressType.accident: 'Accident',
    DistressType.fire: 'Incendie',
    DistressType.other: 'Autre',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAsync = ref.watch(activeSosStreamProvider);
    final myUid = ref.watch(currentUidProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.emergency_share_outlined, color: AppColors.sos),
            SizedBox(width: 8),
            Text(
              'SOS à proximité',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: sosAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final sos = alerts[index];
              // Sa propre alerte n'a pas d'action « Je réponds ».
              final isMine = sos.userId == myUid;
              // Déjà intervenant (présent dans le registre, avec un suivi
              // non désisté): le bouton rouvre la fiche d'intervention au
              // lieu de griser.
              final alreadyResponding = sos.responderIds.contains(myUid);
              return _SosCard(
                sos: sos,
                label: _labels[sos.distressType] ?? sos.distressType.name,
                isResponding: alreadyResponding,
                onRespond: isMine
                    ? null
                    : alreadyResponding
                    ? () =>
                          context.router.push(SosResponseDetailRoute(sosAlert: sos))
                    : () => _respond(context, ref, sos),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.sos)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Liste indisponible: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.sos),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext context, WidgetRef ref, SOSAlert sos) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(offerHelpUseCaseProvider).execute(alertId: sos.id);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Impossible de répondre: $e'),
          backgroundColor: AppColors.sos,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    // Le spec demande d'indiquer qu'on se déplace, pas de rester sur une
    // fiche d'information. La page suivante porte la position et les consignes.
    await context.router.push(SosResponseDetailRoute(sosAlert: sos));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green.shade600,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune alerte active à proximité',
            style: TextStyle(color: AppColors.inactive, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _SosCard extends StatelessWidget {
  const _SosCard({
    required this.sos,
    required this.label,
    required this.isResponding,
    required this.onRespond,
  });

  final SOSAlert sos;
  final String label;

  /// J'ai déjà répondu à cette alerte.
  final bool isResponding;

  /// Null quand il n'y a rien à signaler: alerte personnelle, ou je suis déjà
  /// intervenant.
  final VoidCallback? onRespond;

  @override
  Widget build(BuildContext context) {
    final isCritical =
        sos.distressType == DistressType.medical ||
        sos.distressType == DistressType.security;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isCritical
              ? AppColors.sos.withValues(alpha: 0.45)
              : AppColors.inactive.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Badge(label: label, critical: isCritical),
                if (sos.distanceInKm != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.navigation,
                        color: AppColors.secondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${sos.distanceInKm!.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sos.description ?? 'Demande d\'assistance urgente.',
              style: const TextStyle(color: AppColors.primary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            _ResponderLine(count: sos.respondersCount),
            if (onRespond != null || isResponding) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRespond,
                  icon: Icon(
                    isResponding ? Icons.check_circle : Icons.volunteer_activism,
                    size: 18,
                  ),
                  label: Text(
                    isResponding ? 'VOUS ÊTES EN ROUTE' : 'JE RÉPONDS',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isResponding
                        ? Colors.green.shade700
                        : AppColors.sos,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.critical});

  final String label;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: critical ? AppColors.sos : AppColors.inactive,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ResponderLine extends StatelessWidget {
  const _ResponderLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final hasResponders = count > 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            color: hasResponders ? Colors.green.shade700 : AppColors.inactive,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasResponders
                  ? '$count personne${count > 1 ? 's' : ''} en route'
                  : 'Personne ne s\'est encore manifesté',
              style: TextStyle(
                color: hasResponders ? Colors.green.shade800 : AppColors.inactive,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}