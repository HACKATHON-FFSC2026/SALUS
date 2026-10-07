import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/help/domain/entities/public_organization.dart';
import 'package:salus/features/sos/presentation/voice_sos.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends ConsumerWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(publicOrganizationsProvider);
    // Mode invité : proposer de se connecter pour débloquer SOS, refuges, etc.
    final isGuest = ref.watch(authProvider).user == null;
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
          if (isGuest) ...[
            _GuestSignInCard(
              onTap: () => context.router.push(const LoginRoute()),
            ),
            const SizedBox(height: 16),
          ],
          _AssistantEntry(
            onTap: () => context.router.push(const AssistantRoute()),
          ),
          const SizedBox(height: 16),
          // Contenu hors connexion du spec §1.1 : premier secours + mode
          // évacuation. Toujours en premier, l'annuaire demande le réseau.
          Row(
            children: [
              Expanded(
                child: _OfflineGuideTile(
                  icon: Icons.health_and_safety_outlined,
                  label: 'Premiers\nsecours',
                  onTap: () => context.router.push(const FirstAidRoute()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OfflineGuideTile(
                  icon: Icons.directions_run,
                  label: 'Mode\névacuation',
                  onTap: () => context.router.push(EvacuationGuideRoute()),
                ),
              ),
            ],
          ),
          if (isVoiceSosSupported) ...[
            const SizedBox(height: 16),
            const _VoiceSosKeywords(),
          ],
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

/// Carte affichée aux invités : les invite à créer/associer un compte.
class _GuestSignInCard extends StatelessWidget {
  const _GuestSignInCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.secondary.withValues(alpha: .14),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.login, color: AppColors.secondaryText, size: 26),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vous êtes en mode invité',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Connectez-vous pour envoyer un SOS, proposer un refuge '
                    'et signaler un incident.',
                    style: TextStyle(color: AppColors.inactive, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    ),
  );
}

class _AssistantEntry extends StatelessWidget {
  const _AssistantEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.secondary.withValues(alpha: 0.18),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.secondaryText,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Copilote de crise',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Décrivez la situation, obtenez des consignes et écoutez la réponse.',
                    style: TextStyle(color: AppColors.inactive, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    ),
  );
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard(this.organization);

  final PublicOrganization organization;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
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
              const Icon(
                Icons.verified,
                color: AppColors.secondaryText,
                size: 19,
              ),
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
    return 'Le chargement prend trop de temps. Vérifiez votre connexion puis réessayez.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Le service est momentanément indisponible. Réessayez dans un instant.',
      'failed-precondition' =>
        'Le service est en cours de configuration. Réessayez plus tard.',
      'unavailable' =>
        'Connexion indisponible. Vérifiez votre réseau puis réessayez.',
      _ => 'Impossible de charger les organisations. Réessayez plus tard.',
    };
  }
  return 'Impossible de charger les organisations. Réessayez plus tard.';
}

String _organizationType(String value) => switch (value) {
  'ngo' => 'Organisation non gouvernementale',
  'government' => 'Administration publique',
  'emergencyServices' => 'Services d’urgence',
  _ => 'Organisation de secours',
};

/// Info: phrases reconnues par le SOS vocal. La liste vient de
/// `voiceSosPhrases` (feature SOS) pour ne jamais diverger de la grammaire.
class _VoiceSosKeywords extends StatelessWidget {
  const _VoiceSosKeywords();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.inactive.withValues(alpha: 0.25)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(
          Icons.record_voice_over_outlined,
          color: AppColors.primary,
        ),
        title: const Text(
          'Mots-clés du SOS vocal',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: const Text(
          'Phrases reconnues à la voix',
          style: TextStyle(color: AppColors.inactive, fontSize: 13),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quand l’écoute est active, dites l’une de ces phrases pour '
              'envoyer un SOS sans toucher l’écran. La reconnaissance est '
              'locale et fonctionne hors connexion.',
              style: TextStyle(color: AppColors.inactive, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final phrase in voiceSosPhrases) _KeywordChip(phrase),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip(this.phrase);

  final String phrase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        phrase,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OfflineGuideTile extends StatelessWidget {
  const _OfflineGuideTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
