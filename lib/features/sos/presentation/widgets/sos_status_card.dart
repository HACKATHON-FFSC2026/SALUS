import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/providers/public_organization_provider.dart';
import 'package:salus/core/themes/app_theme.dart';

/// État de l'alerte en cours.
///
/// Le statut est porté par le **texte**, en couleur primaire lisible. La
/// pastille colorée n'est qu'un repère secondaire : colorer le titre en
/// orange/bleu/vert sur blanc tombait sous le seuil de contraste AA.
class SosStatusCard extends ConsumerWidget {
  const SosStatusCard({super.key, this.alert});

  /// Null tant que le flux temps réel n'a pas encore répondu. On affiche
  /// quand même l'état « en attente » plutôt qu'un trou dans l'écran.
  final SOSAlert? alert;

  Color _statusColor(SOSStatus status) {
    switch (status) {
      case SOSStatus.waiting:
        return Colors.orange.shade700;
      case SOSStatus.assigned:
        return Colors.deepPurple.shade600;
      case SOSStatus.inProgress:
        return Colors.blue.shade700;
      case SOSStatus.resolved:
        return Colors.green.shade700;
      case SOSStatus.cancelled:
        return AppColors.inactive;
    }
  }

  String _statusText(SOSStatus status) {
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
    final statusColor = _statusColor(status);
    final organizationId = currentAlert?.assignedOrganizationId;
    final organizationName = organizationId == null
        ? null
        : ref.watch(publicOrganizationNameProvider(organizationId));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inactive.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  _statusText(status),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _InfoRow(
            icon: Icons.my_location,
            text:
                'Votre position est partagée en temps réel avec les '
                'secouristes.',
          ),
          if (organizationId != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.apartment_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    organizationName == null
                        ? 'Organisation assignée'
                        : organizationName.when(
                            data: (name) =>
                                'Organisation : ${name ?? "assignée"}',
                            loading: () => 'Organisation : chargement…',
                            error: (_, _) => 'Organisation assignée',
                          ),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.inactive, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.inactive,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
    ],
  );
}
