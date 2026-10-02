import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';

enum ResolutionType {
  situationResolved,
  personSecured,
  transferToShelter,
  other,
}

class SosResolutionModal extends StatefulWidget {
  const SosResolutionModal({super.key});

  @override
  State<SosResolutionModal> createState() => _SosResolutionModalState();
}

class _SosResolutionModalState extends State<SosResolutionModal> {
  ResolutionType _selectedResolution = ResolutionType.situationResolved;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Intervention terminée ?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sélectionnez le résultat de l\'intervention pour clôturer le dossier.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inactive,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.inactive),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Options de résolution
              ...ResolutionType.values.map((type) {
                final isSelected = _selectedResolution == type;
                return _buildResolutionOption(
                  type: type,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedResolution = type;
                    });
                  },
                );
              }),

              const SizedBox(height: 24),

              // Section note optionnelle
              const Text(
                'AJOUTER UNE NOTE (OPTIONNEL)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inactive,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Précisez les détails de la résolution...',
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

              // Bouton confirmer
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'resolutionType': _selectedResolution.name,
                    'note': _noteController.text.isEmpty ? null : _noteController.text,
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
                  'CONFIRMER LA RÉSOLUTION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResolutionOption({
    required ResolutionType type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.inactive.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button custom
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.secondary : AppColors.inactive,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              _getResolutionLabel(type),
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getResolutionLabel(ResolutionType type) {
    switch (type) {
      case ResolutionType.situationResolved:
        return 'Situation résolue';
      case ResolutionType.personSecured:
        return 'Personne mise en sécurité';
      case ResolutionType.transferToShelter:
        return 'Transfert vers un refuge';
      case ResolutionType.other:
        return 'Autre';
    }
  }
}
