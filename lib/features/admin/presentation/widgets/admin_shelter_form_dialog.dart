import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/shelters/domain/models/shelter_location_selection.dart';

class AdminShelterFormDialog extends StatefulWidget {
  const AdminShelterFormDialog({super.key, required this.onCreate});

  final Future<void> Function({
    required String name,
    required String address,
    required int capacityTotal,
    required double latitude,
    required double longitude,
    required Map<String, bool> resources,
  })
  onCreate;

  @override
  State<AdminShelterFormDialog> createState() => _AdminShelterFormDialogState();
}

class _AdminShelterFormDialogState extends State<AdminShelterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _capacity = TextEditingController();
  bool _water = false;
  bool _food = false;
  bool _electricity = false;
  bool _medicalKit = false;
  bool _isSubmitting = false;
  String? _locationError;
  String? _error;
  ShelterLocationSelection? _location;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final selected = await context.router.push<ShelterLocationSelection>(
      ShelterLocationPickerRoute(
        initialLocation: _location?.location,
        initialAddress: _location?.address,
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _location = selected;
      _locationError = null;
    });
    final address = selected.address;
    if (address != null && _address.text.trim().isEmpty) {
      _address.value = TextEditingValue(
        text: address,
        selection: TextSelection.collapsed(offset: address.length),
      );
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _locationError = _location == null
          ? 'Veuillez sélectionner la localisation du refuge.'
          : null;
    });
    if (!valid || _location == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.onCreate(
        name: _name.text.trim(),
        address: _address.text.trim(),
        capacityTotal: int.parse(_capacity.text.trim()),
        latitude: _location!.location.latitude,
        longitude: _location!.location.longitude,
        resources: {
          'water': _water,
          'food': _food,
          'electricity': _electricity,
          'medicalKit': _medicalKit,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error =
            'Impossible de créer le refuge. Vérifiez votre connexion puis réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 620,
        height: size.height * .86,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ajouter un refuge officiel',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _FormSection(
                      title: 'Informations générales',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            enabled: !_isSubmitting,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Nom du refuge',
                              prefixIcon: Icon(Icons.home_work_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Le nom du refuge est obligatoire.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _address,
                            enabled: !_isSubmitting,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Adresse',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'L’adresse est obligatoire.'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    _FormSection(
                      title: 'Localisation',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _pickLocation,
                            icon: Icon(
                              _location == null
                                  ? Icons.location_searching
                                  : Icons.place,
                            ),
                            label: Text(
                              _location == null
                                  ? 'Sélectionner sur la carte'
                                  : 'Modifier la localisation',
                            ),
                          ),
                          if (_location != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_location!.address ?? 'Position sélectionnée'} · '
                              '${_location!.location.latitude.toStringAsFixed(5)}, '
                              '${_location!.location.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: AppColors.inactive,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (_locationError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _locationError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _FormSection(
                      title: 'Capacité',
                      child: TextFormField(
                        controller: _capacity,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Capacité totale',
                          suffixText: 'places',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        validator: (value) {
                          final capacity = int.tryParse(value?.trim() ?? '');
                          if (capacity == null) {
                            return 'Saisissez une capacité entière.';
                          }
                          if (capacity <= 0) {
                            return 'La capacité doit être supérieure à 0.';
                          }
                          return null;
                        },
                      ),
                    ),
                    _FormSection(
                      title: 'Ressources disponibles',
                      child: Column(
                        children: [
                          _ResourceOption(
                            label: 'Eau',
                            icon: Icons.water_drop_outlined,
                            value: _water,
                            onChanged: (value) =>
                                setState(() => _water = value),
                          ),
                          _ResourceOption(
                            label: 'Nourriture',
                            icon: Icons.restaurant_outlined,
                            value: _food,
                            onChanged: (value) => setState(() => _food = value),
                          ),
                          _ResourceOption(
                            label: 'Électricité',
                            icon: Icons.bolt_outlined,
                            value: _electricity,
                            onChanged: (value) =>
                                setState(() => _electricity = value),
                          ),
                          _ResourceOption(
                            label: 'Kit médical',
                            icon: Icons.medical_services_outlined,
                            value: _medicalKit,
                            onChanged: (value) =>
                                setState(() => _medicalKit = value),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: const Text('Créer et valider'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surface,
    elevation: 1,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _ResourceOption extends StatelessWidget {
  const _ResourceOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: value,
    onChanged: (checked) => onChanged(checked ?? false),
    title: Text(label),
    secondary: Icon(icon, color: AppColors.primary),
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    activeColor: AppColors.primary,
  );
}
