import 'package:flutter/material.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';

class SosDistressModal extends StatefulWidget {
  const SosDistressModal({super.key});

  @override
  State<SosDistressModal> createState() => _SosDistressModalState();
}

class _SosDistressModalState extends State<SosDistressModal> {
  DistressType _selectedDistressType = DistressType.other;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  IconData _getIconForDistressType(DistressType type) {
    switch (type) {
      case DistressType.medical:
        return Icons.medical_services;
      case DistressType.security:
        return Icons.security;
      case DistressType.accident:
        return Icons.car_crash;
      case DistressType.fire:
        return Icons.local_fire_department;
      case DistressType.other:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Type d\'urgence',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.inactive),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Sélection du type de détresse
              const Text(
                'Sélectionnez le type d\'urgence :',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.inactive,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DistressType.values.map((type) {
                  final isSelected = _selectedDistressType == type;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDistressType = type;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.inactive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForDistressType(type),
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.frenchLabel,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Description (facultatif)
              const Text(
                'Description (facultatif) :',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.inactive,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Décrivez votre situation...',
                  hintStyle: const TextStyle(color: AppColors.inactive),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bouton de confirmation
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'distressType': _selectedDistressType,
                    'description': _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Envoyer l\'alerte SOS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
