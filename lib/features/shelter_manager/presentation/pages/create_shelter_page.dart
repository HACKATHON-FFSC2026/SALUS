import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/shelter_manager/domain/entities/shelter_draft.dart';
import 'package:salus/features/shelter_manager/presentation/providers/shelter_manager_providers.dart';
import 'package:salus/features/shelter_manager/presentation/shelter_ui.dart';
import 'package:salus/features/shelters/domain/models/shelter_location_selection.dart';
import 'package:salus/core/entities/shelter_entity.dart';


typedef PickLocation = Future<ShelterLocationSelection?> Function(
  GeoPoint? initialLocation,
  String? initialAddress,
);

/// Création d'un refuge par le gestionnaire. Le refuge est créé fermé, en
/// attente de validation (même circuit que le portail). Retourne l'id créé.
class ManagerCreateShelterPage extends ConsumerStatefulWidget {
  const ManagerCreateShelterPage({super.key, required this.onPickLocation});

  /// Ouvre ShelterLocationPickerPage (fourni par la page parente, qui a
  /// accès au routeur).
  final PickLocation onPickLocation;

  @override
  ConsumerState<ManagerCreateShelterPage> createState() =>
      _ManagerCreateShelterPageState();
}

class _ManagerCreateShelterPageState
    extends ConsumerState<ManagerCreateShelterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _capacity = TextEditingController();

  GeoPoint? _location;
  bool _locationMissing = false;
  ShelterResources _resources = const ShelterResources();

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _capacity.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  Future<void> _pickLocation() async {
    final selection = await widget.onPickLocation(
      _location,
      _address.text.trim().isEmpty ? null : _address.text.trim(),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _location = selection.location;
      _locationMissing = false;
      final address = selection.address;
      if (address != null && address.isNotEmpty) _address.text = address;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    if (_location == null) setState(() => _locationMissing = true);
    if (!valid || _location == null) return;

    final id = await ref.read(shelterActionsProvider.notifier).createShelter(
          ShelterDraft(
            name: _name.text,
            address: _address.text,
            location: _location!,
            capacityTotal: int.parse(_capacity.text.trim()),
            resources: _resources,
          ),
        );
    if (id != null && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(shelterActionsProvider).isLoading;
    final loc = _location;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Créer un refuge')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.sentences,
                          decoration:
                              const InputDecoration(labelText: 'Nom du refuge'),
                          validator: (v) => (v ?? '').trim().length < 3
                              ? '3 caractères minimum'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _pickLocation,
                          icon: Icon(loc == null
                              ? Icons.add_location_alt_outlined
                              : Icons.edit_location_alt),
                          label: Text(loc == null
                              ? 'Choisir la position sur la carte'
                              : 'Position choisie · modifier'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: _locationMissing
                                ? const BorderSide(color: AppColors.sos)
                                : null,
                          ),
                        ),
                        if (loc != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${loc.latitude.toStringAsFixed(5)}, '
                              '${loc.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                  color: AppColors.inactive, fontSize: 12),
                            ),
                          ),
                        if (_locationMissing)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('Position obligatoire',
                                style: TextStyle(
                                    color: AppColors.sos, fontSize: 12)),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _address,
                          decoration:
                              const InputDecoration(labelText: 'Adresse'),
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _capacity,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Capacité (personnes)'),
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            return (n == null || n <= 0)
                                ? 'Nombre invalide'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Ressources disponibles à l’ouverture',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _switch('Eau potable', Icons.water_drop_outlined,
                            _resources.water,
                            (v) => _resources = _resources.copyWith(water: v)),
                        const Divider(height: 1),
                        _switch('Nourriture', Icons.restaurant_outlined,
                            _resources.food,
                            (v) => _resources = _resources.copyWith(food: v)),
                        const Divider(height: 1),
                        _switch('Électricité', Icons.bolt_outlined,
                            _resources.electricity,
                            (v) => _resources = _resources.copyWith(electricity: v)),
                        const Divider(height: 1),
                        _switch('Trousse médicale',
                            Icons.medical_services_outlined, _resources.medicalKit,
                            (v) => _resources = _resources.copyWith(medicalKit: v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Le refuge sera créé fermé et soumis à validation par '
                    'l’équipe avant d’être visible de tous.',
                    style: TextStyle(color: AppColors.inactive, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                    child: busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Créer le refuge'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switch(
    String label,
    IconData icon,
    bool value,
    void Function(bool) apply,
  ) =>
      SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(label),
        value: value,
        onChanged: (v) => setState(() => apply(v)),
      );
}
