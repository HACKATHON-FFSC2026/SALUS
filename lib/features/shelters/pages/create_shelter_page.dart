import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/map/services/location_service.dart';
import 'package:salus/features/shelters/domain/models/shelter_creation_state.dart';
import 'package:salus/features/shelters/presentation/controllers/shelter_creation_controller.dart';

/// Formulaire de création d'une fiche refuge (Secouriste / Organisation).
@RoutePage()
class CreateShelterPage extends ConsumerStatefulWidget {
  const CreateShelterPage({super.key});

  @override
  ConsumerState<CreateShelterPage> createState() => _CreateShelterPageState();
}

class _CreateShelterPageState extends ConsumerState<CreateShelterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _water = false;
  bool _food = false;
  bool _electricity = false;
  bool _medicalKit = false;

  GeoPoint? _location;
  bool _isLocating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // Le provider est global : on repart d'un état vierge à chaque ouverture.
    Future.microtask(
      () => ref.read(shelterCreationControllerProvider.notifier).reset(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _notify(String message, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  /// Récupère la position du refuge via le service de localisation existant.
  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _location = GeoPoint(position.latitude, position.longitude);
        _locationError = null;
      });
      _notify('Position du refuge enregistrée.', ToastificationType.success);
    } catch (e) {
      if (!mounted) return;
      // LocationService remonte déjà des messages compréhensibles.
      final message = e is String
          ? e
          : 'Impossible de récupérer la position GPS.';
      setState(() => _locationError = message);
      _notify(message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final location = _location;
    final isFormValid = _formKey.currentState?.validate() ?? false;

    setState(() {
      _locationError = location == null
          ? 'Veuillez définir la position du refuge.'
          : null;
    });

    if (!isFormValid || location == null) return;

    await ref
        .read(shelterCreationControllerProvider.notifier)
        .createShelter(
          name: _nameController.text,
          address: _addressController.text,
          location: location,
          capacityTotal: int.parse(_capacityController.text.trim()),
          resources: ShelterResources(
            water: _water,
            food: _food,
            electricity: _electricity,
            medicalKit: _medicalKit,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ShelterCreationState>(shelterCreationControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == ShelterCreationStatus.success) {
        _notify('Refuge créé avec succès.', ToastificationType.success);
        context.router.maybePop();
      } else if (next.status == ShelterCreationStatus.error) {
        _notify(
          next.errorMessage ?? 'Création du refuge impossible.',
          ToastificationType.error,
        );
      }
    });

    final isSubmitting = ref.watch(
      shelterCreationControllerProvider.select((state) => state.isSubmitting),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un refuge')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SectionCard(
                title: 'Informations générales',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nom du refuge',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Le nom du refuge est obligatoire.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'L\'adresse est obligatoire.'
                          : null,
                    ),
                  ],
                ),
              ),
              _SectionCard(
                title: 'Localisation',
                child: _buildLocation(isSubmitting),
              ),
              _SectionCard(
                title: 'Capacité',
                child: TextFormField(
                  controller: _capacityController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Capacité totale',
                    suffixText: 'places',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'La capacité totale est obligatoire.';
                    }
                    final capacity = int.tryParse(text);
                    if (capacity == null) {
                      return 'Saisissez un nombre entier.';
                    }
                    if (capacity <= 0) {
                      return 'La capacité doit être supérieure à 0.';
                    }
                    return null;
                  },
                ),
              ),
              _SectionCard(
                title: 'Ressources disponibles',
                child: Column(
                  children: [
                    _ResourceCheckbox(
                      label: 'Eau',
                      icon: Icons.water_drop_outlined,
                      value: _water,
                      onChanged: isSubmitting
                          ? null
                          : (checked) => setState(() => _water = checked),
                    ),
                    _ResourceCheckbox(
                      label: 'Nourriture',
                      icon: Icons.restaurant_outlined,
                      value: _food,
                      onChanged: isSubmitting
                          ? null
                          : (checked) => setState(() => _food = checked),
                    ),
                    _ResourceCheckbox(
                      label: 'Électricité',
                      icon: Icons.bolt_outlined,
                      value: _electricity,
                      onChanged: isSubmitting
                          ? null
                          : (checked) => setState(() => _electricity = checked),
                    ),
                    _ResourceCheckbox(
                      label: 'Kit médical',
                      icon: Icons.medical_services_outlined,
                      value: _medicalKit,
                      onChanged: isSubmitting
                          ? null
                          : (checked) => setState(() => _medicalKit = checked),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Créer le refuge'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocation(bool isSubmitting) {
    final location = _location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              location == null
                  ? Icons.location_searching
                  : Icons.check_circle_outline,
              color: location == null ? AppColors.inactive : Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                location == null
                    ? 'Aucune position définie.'
                    : 'Latitude ${location.latitude.toStringAsFixed(5)}, '
                          'longitude ${location.longitude.toStringAsFixed(5)}',
                style: TextStyle(
                  color: location == null
                      ? AppColors.inactive
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 8),
          Text(
            _locationError!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isLocating || isSubmitting ? null : _useCurrentLocation,
          icon: _isLocating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(
            location == null
                ? 'Utiliser ma position actuelle'
                : 'Actualiser ma position',
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
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
}

class _ResourceCheckbox extends StatelessWidget {
  const _ResourceCheckbox({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged?.call(checked ?? false),
      title: Text(label),
      secondary: Icon(icon, color: AppColors.primary),
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primary,
    );
  }
}
