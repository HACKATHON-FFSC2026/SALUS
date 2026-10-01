import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/emergency_numbers.dart';

/// Appel direct au numéro d'urgence concerné.
///
/// Le libellé porte le service (« Police », « Pompiers », « SAMU ») pour que
/// l'utilisateur sache où il appelle: sur une liste de numéros indiscernables,
/// il choisit au hasard et perd du temps.
class CallEmergencyButton extends StatelessWidget {
  const CallEmergencyButton({
    super.key,
    required this.numbers,
  });

  final EmergencyNumbers numbers;

  Future<void> _call(BuildContext context, String number) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await _tryLaunch(uri);
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Appel impossible. Composez le $number.'),
          backgroundColor: AppColors.sos,
        ),
      );
    }
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String)>[
      ('Police', numbers.police),
      ('Pompiers', numbers.fire),
      if (numbers.ambulance != null) ('SAMU', numbers.ambulance!),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Appeler les secours',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _EmergencyChip(
                    label: entries[i].$1,
                    number: entries[i].$2,
                    onTap: () => _call(context, entries[i].$2),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmergencyChip extends StatelessWidget {
  const _EmergencyChip({
    required this.label,
    required this.number,
    required this.onTap,
  });

  final String label;
  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Appeler $label, $number',
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(color: AppColors.sos.withValues(alpha: 0.35), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              number,
              style: const TextStyle(
                color: AppColors.sos,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}