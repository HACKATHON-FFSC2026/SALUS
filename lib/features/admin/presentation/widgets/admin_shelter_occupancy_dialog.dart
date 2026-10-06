import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';

/// Met à jour le nombre de places occupées d'un refuge.
///
/// C'est l'écriture qui alimente la disponibilité affichée aux citoyens ; sans
/// elle, la barre de capacité reste figée sur la valeur de création (0).
/// Réservé à l'admin : les règles Firestore n'autorisent que `isAdmin()` à
/// écrire ce champ.
class AdminShelterOccupancyDialog extends StatefulWidget {
  const AdminShelterOccupancyDialog({
    super.key,
    required this.shelterName,
    required this.capacityTotal,
    required this.capacityOccupied,
    required this.onSave,
  });

  final String shelterName;
  final int capacityTotal;
  final int capacityOccupied;
  final Future<void> Function(int capacityOccupied) onSave;

  @override
  State<AdminShelterOccupancyDialog> createState() =>
      _AdminShelterOccupancyDialogState();
}

class _AdminShelterOccupancyDialogState
    extends State<AdminShelterOccupancyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _occupied = TextEditingController(
    text: '${widget.capacityOccupied}',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _occupied.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(int.parse(_occupied.text.trim()));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Mise à jour impossible. Vérifiez la connexion puis réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Occupation du refuge'),
    content: SizedBox(
      width: 400,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.shelterName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _occupied,
              enabled: !_saving,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Places occupées',
                suffixText: 'sur ${widget.capacityTotal}',
                prefixIcon: const Icon(Icons.groups_outlined),
              ),
              validator: (value) {
                final occupied = int.tryParse(value?.trim() ?? '');
                if (occupied == null) return 'Saisissez un nombre entier.';
                if (occupied < 0) return 'Le nombre ne peut pas être négatif.';
                if (occupied > widget.capacityTotal) {
                  return 'Ne peut pas dépasser ${widget.capacityTotal}.';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (!_saving) _save();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'La disponibilité affichée aux citoyens est recalculée à partir '
              'de ce nombre.',
              style: TextStyle(color: AppColors.inactive, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Enregistrer'),
      ),
    ],
  );
}
