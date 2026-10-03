import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';

class CancelSosButton extends StatelessWidget {
  const CancelSosButton({
    super.key,
    required this.onConfirmCancel,
    this.isBusy = false,
  });

  final VoidCallback onConfirmCancel;

  /// Annulation en cours d'écriture: le bouton se verrouille pour ne pas
  /// empiler les requêtes.
  final bool isBusy;

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Êtes-vous en sécurité ?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Cette action annulera l\'alerte SOS et en informera les intervenants.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Non, maintenir l\'alerte'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirmCancel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Oui, annuler la demande',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: isBusy ? null : () => _showConfirmationDialog(context),
        icon: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline, color: Colors.green),
        label: const Text(
          'Je suis en sécurité (Annuler SOS)',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: Colors.green, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}