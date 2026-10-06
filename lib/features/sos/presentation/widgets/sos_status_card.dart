import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/providers/public_organization_provider.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/sos/presentation/providers/responder_controller.dart';

class SosStatusCard extends ConsumerWidget {
  const SosStatusCard({super.key, this.alert});

  /// Null tant que le flux temps réel n'a pas encore répondu. On affiche
  /// quand même l'état « en attente » plutôt qu'un trou dans l'écran.
  final SOSAlert? alert;

  Color _getStatusColor(SOSStatus status) {
    switch (status) {
      case SOSStatus.waiting:
        return Colors.orange;
      case SOSStatus.assigned:
        return Colors.deepPurple;
      case SOSStatus.inProgress:
        return Colors.blue;
      case SOSStatus.resolved:
        return Colors.green;
      case SOSStatus.cancelled:
        return AppColors.inactive;
    }
  }

  String _getStatusText(SOSStatus status) {
    switch (status) {
      case SOSStatus.waiting:
        // « En attente de secours » laissait croire que des secours étaient
        // déjà prévenus. À ce statut, personne n'est encore affecté.
        return 'Alerte transmise, en attente d\'une équipe';
      case SOSStatus.assigned:
        return 'Organisation assignée';
      case SOSStatus.inProgress:
        return 'Intervention en cours';
      case SOSStatus.resolved:
        return 'Alerte résolue';
      case SOSStatus.cancelled:
        return 'Alerte annulée';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAlert = alert;
    final status = currentAlert?.status ?? SOSStatus.waiting;
    // Compté depuis les suivis actifs, pas depuis `respondersCount`: ce dernier
    // vient du registre append-only qui garde les intervenants retirés, et
    // gonflait le nombre affiché à la victime.
    final responders = currentAlert == null
        ? 0
        : ref
              .watch(respondersProvider(currentAlert.id))
              .maybeWhen(
                data: (items) => items.length,
                orElse: () => currentAlert.respondersCount,
              );
    final statusColor = _getStatusColor(status);
    final organizationId = currentAlert?.assignedOrganizationId;
    final organizationName = organizationId == null
        ? null
        : ref.watch(publicOrganizationNameProvider(organizationId));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (organizationId != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.apartment_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Organisation :',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: organizationName == null
                      ? const Text('Assignée')
                      : organizationName.when(
                          data: (name) => Text(name ?? 'Assignée'),
                          loading: () => const Text('Chargement…'),
                          error: (_, _) => const Text('Assignée'),
                        ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personnes en route :',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$responders',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
