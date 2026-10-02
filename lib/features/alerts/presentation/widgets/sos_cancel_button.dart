import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/alerts/presentation/providers/alerts_provider.dart';

class SosCancelButton extends ConsumerWidget {
  final String alertId;
  final VoidCallback? onSuccess;

  const SosCancelButton({super.key, required this.alertId, this.onSuccess});

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    // Boîte de dialogue de confirmation stylisée
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.shield, color: AppColors.secondary, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Je suis en sécurité',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Voulez-vous annuler l\'alerte SOS et confirmer que vous n\'avez plus besoin d\'aide ?',
            style: TextStyle(fontSize: 14, color: AppColors.primary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Non, maintenir',
                style: TextStyle(color: AppColors.inactive),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(120, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Oui, annuler',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    // Exécution de l'annulation via Riverpod
    if (confirm == true && context.mounted) {
      try {
        await ref.read(alertsControllerProvider.notifier).cancelSos(alertId);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible d’annuler le SOS : $error')),
          );
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre alerte SOS a été annulée avec succès.'),
            backgroundColor: AppColors.primary,
          ),
        );
        if (onSuccess != null) {
          onSuccess!();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(alertsControllerProvider).isLoading;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
        ),
        onPressed: isLoading ? null : () => _handleCancel(context, ref),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Je suis en sécurité (Annuler SOS)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
