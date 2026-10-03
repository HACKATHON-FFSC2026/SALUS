import 'package:flutter/material.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';

class SosStatusCard extends StatelessWidget {
  const SosStatusCard({super.key, this.alert});

  /// Null tant que le flux temps réel n'a pas encore répondu. On affiche
  /// quand même l'état « en attente » plutôt qu'un trou dans l'écran.
  final SOSAlert? alert;

  Color _getStatusColor(SOSStatus status) {
    switch (status) {
      case SOSStatus.waiting:
        return Colors.orange;
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
        return 'En attente de secours';
      case SOSStatus.inProgress:
        return 'Secours en route';
      case SOSStatus.resolved:
        return 'Alerte résolue';
      case SOSStatus.cancelled:
        return 'Alerte annulée';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = alert?.status ?? SOSStatus.waiting;
    final responders = alert?.respondersCount ?? 0;
    final statusColor = _getStatusColor(status);

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
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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