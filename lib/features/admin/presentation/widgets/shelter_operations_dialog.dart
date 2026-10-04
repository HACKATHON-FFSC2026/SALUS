import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/shelter_operational_status.dart';

class ShelterOperationsDialog extends StatefulWidget {
  const ShelterOperationsDialog({
    super.key,
    required this.capacityTotal,
    required this.capacityOccupied,
    required this.status,
    required this.onSave,
  });

  final int capacityTotal;
  final int capacityOccupied;
  final ShelterOperationalStatus status;
  final Future<void> Function(
    ShelterOperationalStatus status,
    int capacityOccupied,
  )
  onSave;

  @override
  State<ShelterOperationsDialog> createState() =>
      _ShelterOperationsDialogState();
}

class _ShelterOperationsDialogState extends State<ShelterOperationsDialog> {
  late final TextEditingController _occupiedController;
  late ShelterOperationalStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _occupiedController = TextEditingController(
      text: widget.capacityOccupied.toString(),
    );
    _status = widget.status;
  }

  @override
  void dispose() {
    _occupiedController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final occupied = int.tryParse(_occupiedController.text);
    if (occupied == null || occupied < 0 || occupied > widget.capacityTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Indiquez une occupation entre 0 et ${widget.capacityTotal}.',
          ),
          backgroundColor: AppColors.sos,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(_status, occupied);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mise à jour impossible : $error'),
          backgroundColor: AppColors.sos,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Disponibilité du refuge'),
    content: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ShelterOperationalStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Statut'),
            items: const [
              DropdownMenuItem(
                value: ShelterOperationalStatus.open,
                child: Text('Ouvert'),
              ),
              DropdownMenuItem(
                value: ShelterOperationalStatus.almostFull,
                child: Text('Presque complet'),
              ),
              DropdownMenuItem(
                value: ShelterOperationalStatus.full,
                child: Text('Complet'),
              ),
              DropdownMenuItem(
                value: ShelterOperationalStatus.closed,
                child: Text('Fermé'),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) setState(() => _status = value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _occupiedController,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Places occupées',
              helperText: 'Capacité totale : ${widget.capacityTotal}',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
