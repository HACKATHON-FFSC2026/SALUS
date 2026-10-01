import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';

class CancelSosButton extends StatelessWidget {
  final VoidCallback onConfirmCancel;

  const CancelSosButton({super.key, required this.onConfirmCancel});

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
        onPressed: () => _showConfirmationDialog(context),
        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
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