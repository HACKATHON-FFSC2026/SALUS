import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/help/domain/entities/public_organization.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends ConsumerWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(publicOrganizationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Aide')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent, color: Colors.white, size: 30),
                SizedBox(height: 10),
                Text(
                  'Besoin d’aide ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Contactez une organisation vérifiée près de vous.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Organisations disponibles',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Seules les organisations validées et actives sont affichées.',
            style: TextStyle(color: AppColors.inactive, fontSize: 13),
          ),
          const SizedBox(height: 12),
          organizations.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _DirectoryMessage(
              icon: Icons.cloud_off_outlined,
              message: _organizationErrorMessage(error),
              onRetry: () => ref.invalidate(publicOrganizationsProvider),
            ),
            data: (items) => items.isEmpty
                ? const _DirectoryMessage(
                    icon: Icons.apartment_outlined,
                    message: 'Aucune organisation vérifiée pour le moment.',
                  )
                : Column(
                    children: [
                      for (final organization in items)
                        _OrganizationCard(organization),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard(this.organization);

  final PublicOrganization organization;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  organization.name,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.verified, color: AppColors.secondary, size: 19),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              _organizationType(organization.type),
              style: const TextStyle(color: AppColors.inactive, fontSize: 13),
            ),
          ),
          if (organization.phone?.trim().isNotEmpty == true)
            _ContactButton(
              icon: Icons.phone_outlined,
              label: organization.phone!.trim(),
              onPressed: () => _launch(
                context,
                Uri(scheme: 'tel', path: organization.phone!.trim()),
              ),
            ),
          if (organization.email?.trim().isNotEmpty == true)
            _ContactButton(
              icon: Icons.email_outlined,
              label: organization.email!.trim(),
              onPressed: () => _launch(
                context,
                Uri(scheme: 'mailto', path: organization.email!.trim()),
              ),
            ),
          if (organization.phone?.trim().isNotEmpty != true &&
              organization.email?.trim().isNotEmpty != true)
            const Padding(
              padding: EdgeInsets.only(left: 34, top: 8),
              child: Text(
                'Aucune coordonnée de contact renseignée.',
                style: TextStyle(color: AppColors.inactive, fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (await launchUrl(uri)) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir cette application.')),
      );
    }
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: TextButton.styleFrom(alignment: Alignment.centerLeft),
  );
}

class _DirectoryMessage extends StatelessWidget {
  const _DirectoryMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(icon, color: AppColors.inactive, size: 34),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inactive),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ],
    ),
  );
}

String _organizationErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Le chargement prend trop de temps. Vérifie ta connexion puis réessaie.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Firebase a refusé la lecture. Vérifie dans le projet salus-bd055 que les règles publiées autorisent la lecture des organisations vérifiées et actives.',
      'failed-precondition' =>
        'Index Firestore manquant. Déploie les index du projet puis réessaie.',
      'unavailable' =>
        'Firestore est momentanément indisponible. Réessaie dans un instant.',
      _ => 'Impossible de charger les organisations (${error.code}).',
    };
  }
  return 'Impossible de charger les organisations.';
}

String _organizationType(String value) => switch (value) {
  'ngo' => 'Organisation non gouvernementale',
  'government' => 'Administration publique',
  'emergencyServices' => 'Services d’urgence',
  _ => 'Organisation de secours',
};
