import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';

class CallEmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CallEmergencyButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.phone, color: AppColors.primary),
        label: const Text(
          'Appeler les secours',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.inactive.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}