import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/first_aid_guidelines.dart';

/// Fiche d'intervention affichée après « JE RÉPONDS ».
///
/// Elle porte deux choses: où aller, et quoi faire en attendant. Les consignes
/// viennent de [FirstAidGuideline], donc dépendantes du type de détresse
/// annoncé, pas d'une liste générique identique pour un incendie et pour une
/// agression.
@RoutePage()
class SosResponseDetailPage extends StatelessWidget {
  const SosResponseDetailPage({super.key, required this.sosAlert});

  final SOSAlert sosAlert;

  Future<void> _openMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${sosAlert.location.latitude},${sosAlert.location.longitude}',
    );
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('navigation refusée');
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Itinéraire indisponible. Coordonnées: '
            '${sosAlert.location.latitude.toStringAsFixed(4)}, '
            '${sosAlert.location.longitude.toStringAsFixed(4)}',
          ),
          backgroundColor: AppColors.sos,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideline = FirstAidGuideline.getGuidelinesFor(
      sosAlert.distressType,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Intervention en cours',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Acknowledgement(),
            const SizedBox(height: 16),
            _SummaryCard(alert: sosAlert),
            const SizedBox(height: 24),
            Text(
              guideline.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final step in guideline.steps) _Step(text: step),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _openMaps(context),
              icon: const Icon(Icons.near_me, color: Colors.white),
              label: const Text(
                'ITINÉRAIRE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Acknowledgement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vous avez répondu à cet appel',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Votre position est partagée tant que l\'alerte est active.',
                  style: TextStyle(color: AppColors.inactive, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.alert});

  final SOSAlert alert;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.inactive.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sos,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.distressType.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (alert.distanceInKm != null)
                  Text(
                    '${alert.distanceInKm!.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.description ?? 'Demande d\'assistance urgente.',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.primary, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}