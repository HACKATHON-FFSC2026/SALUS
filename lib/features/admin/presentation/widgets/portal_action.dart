import 'package:flutter/material.dart';

/// Exécute une action à effet du portail : confirmation facultative, puis
/// retour de succès ou d'échec.
///
/// Les actions du portail écrivaient en « fire and forget » : aucun dialogue,
/// aucun accusé. Un mauvais clic suspendait une organisation ou désactivait un
/// compte sans qu'on sache si c'était passé. Ce helper impose les deux.
Future<void> runPortalAction(
  BuildContext context, {
  required Future<void> Function() action,
  required String successMessage,
  String? confirmTitle,
  String? confirmMessage,
  String confirmLabel = 'Confirmer',
  IconData? confirmIcon,
  bool destructive = false,
}) async {
  if (confirmTitle != null) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirmTitle),
        content: confirmMessage == null ? null : Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor: Colors.white,
                  )
                : null,
            icon: Icon(confirmIcon ?? (destructive ? Icons.warning_amber_rounded : Icons.check)),
            label: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }

  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Action impossible. Vérifiez la connexion puis réessayez.',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
