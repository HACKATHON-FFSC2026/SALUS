import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/usecases/send_sos_usecase.dart';
import '../distress_label.dart';
import '../providers/active_sos_provider.dart';
import '../providers/responder_controller.dart';

/// Évite le « 0.00 km » illisible en dessous du kilomètre.
String _distanceLabel(double km) => km < 0.95
    ? '${(km * 1000).round()} m'
    : '${km.toStringAsFixed(1)} km';

/// Âge d'une alerte. Le fait décisif pour décider d'y aller ou non.
String _ageLabel(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'À l\'instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  return 'Il y a ${diff.inDays} j';
}

@RoutePage()
class ActiveSosListPage extends ConsumerWidget {
  const ActiveSosListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAsync = ref.watch(activeSosStreamProvider);
    final originAsync = ref.watch(sosOriginProvider);
    final nearbyOnly = ref.watch(sosNearbyScopeProvider);
    final myUid = ref.watch(currentUidProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.emergency_share_outlined, color: AppColors.sos),
            SizedBox(width: 8),
            Text(
              'SOS actifs',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: myUid == null
          ? _GuestPrompt(
              onSignIn: () => context.router.push(const LoginRoute()),
            )
          : Column(
        children: [
          // Sans permission, la liste est globale et sans distance. Le dire,
          // et donner le moyen de l'activer, plutôt que de titrer « à
          // proximité » une liste qui ne l'est pas.
          if (originAsync.hasValue && originAsync.value == null)
            _LocationScopeNotice(onEnable: () => _enableLocation(ref))
          // Une fois la position connue, on peut rester coincé sur une vue
          // « proche » vide : garder le sélecteur pour revenir à la liste
          // globale.
          else if (originAsync.hasValue)
            _ScopeSelector(
              nearbyOnly: nearbyOnly,
              onChanged: (value) =>
                  ref.read(sosNearbyScopeProvider.notifier).setNearby(value),
            ),
          Expanded(
            child: sosAsync.when(
              data: (alerts) {
                if (alerts.isEmpty) {
                  final nearby = nearbyOnly && originAsync.value != null;
                  return _EmptyState(
                    nearbyOnly: nearby,
                    onShowAll: nearby
                        ? () => ref
                              .read(sosNearbyScopeProvider.notifier)
                              .setNearby(false)
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final sos = alerts[index];
                    // Sa propre alerte n'a pas d'action « Je réponds ».
                    final isMine = sos.userId == myUid;
                    // Déjà intervenant (présent dans le registre, avec un suivi
                    // non désisté): le bouton rouvre la fiche d'intervention au
                    // lieu de griser.
                    final alreadyResponding = sos.responderIds.contains(myUid);
                    return _SosCard(
                      sos: sos,
                      isResponding: alreadyResponding,
                      onRespond: isMine
                          ? null
                          : alreadyResponding
                          ? () => context.router.push(
                              SosResponseDetailRoute(sosAlert: sos),
                            )
                          : () => _respond(context, ref, sos),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.sos),
              ),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: AppColors.inactive,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger les alertes SOS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.inactive),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(activeSosStreamProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableLocation(WidgetRef ref) async {
    await requestLocationPermission();
    ref.invalidate(sosOriginProvider);
  }

  Future<void> _respond(BuildContext context, WidgetRef ref, SOSAlert sos) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(offerHelpUseCaseProvider).execute(alertId: sos.id);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Impossible de répondre. Réessayez.'),
          backgroundColor: AppColors.sos,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    // Le spec demande d'indiquer qu'on se déplace, pas de rester sur une
    // fiche d'information. La page suivante porte la position et les consignes.
    await context.router.push(SosResponseDetailRoute(sosAlert: sos));
  }
}

class _LocationScopeNotice extends StatelessWidget {
  const _LocationScopeNotice({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.secondary.withValues(alpha: .14),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Localisation désactivée : toutes les alertes sont affichées, '
              'sans distance. Activez-la pour voir les plus proches.',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
          TextButton(onPressed: onEnable, child: const Text('Activer')),
        ],
      ),
    ),
  );
}

/// Bascule entre la liste « près de moi » et la liste globale. Visible tant que
/// la position est connue, pour ne jamais enfermer l'utilisateur dans une vue
/// filtrée vide.
class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.nearbyOnly, required this.onChanged});

  final bool nearbyOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: [
          _ScopeOption(
            selected: !nearbyOnly,
            icon: Icons.public,
            label: 'Toutes',
            onTap: () => onChanged(false),
          ),
          _ScopeOption(
            selected: nearbyOnly,
            icon: Icons.my_location,
            label: 'Près de moi',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    ),
  );
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.inactive,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.inactive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Invité : la lecture des alertes SOS exige un compte. On ne requête rien et
/// on propose de se connecter.
class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Connectez-vous pour voir les alertes SOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les alertes SOS sont réservées aux comptes connectés. '
            'En urgence immédiate, appelez le 112.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inactive, height: 1.35),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onSignIn,
            icon: const Icon(Icons.login),
            label: const Text('Se connecter'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.nearbyOnly = false, this.onShowAll});

  /// Vue filtrée par proximité : des alertes peuvent exister plus loin.
  final bool nearbyOnly;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green.shade600,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              nearbyOnly ? 'Aucune alerte à proximité' : 'Aucune alerte active',
              style: const TextStyle(color: AppColors.inactive, fontSize: 16),
            ),
            if (nearbyOnly && onShowAll != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onShowAll,
                icon: const Icon(Icons.public, size: 18),
                label: const Text('Voir toutes les alertes'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SosCard extends StatelessWidget {
  const _SosCard({
    required this.sos,
    required this.isResponding,
    required this.onRespond,
  });

  final SOSAlert sos;

  /// J'ai déjà répondu à cette alerte.
  final bool isResponding;

  /// Null quand il n'y a rien à signaler: alerte personnelle, ou je suis déjà
  /// intervenant.
  final VoidCallback? onRespond;

  @override
  Widget build(BuildContext context) {
    final isCritical = sos.distressType.isCritical;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isCritical
              ? AppColors.sos.withValues(alpha: 0.45)
              : AppColors.inactive.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Badge(distressType: sos.distressType),
                if (sos.distanceInKm != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.navigation,
                        color: AppColors.secondaryText,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _distanceLabel(sos.distanceInKm!),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sos.description ?? 'Demande d\'assistance urgente.',
              style: const TextStyle(color: AppColors.primary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              _ageLabel(sos.createdAt),
              style: const TextStyle(color: AppColors.inactive, fontSize: 11),
            ),
            const SizedBox(height: 12),
            _ResponderLine(count: sos.respondersCount),
            if (onRespond == null && !isResponding) ...[
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.inactive,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'C\'est votre alerte. Suivez son avancement depuis '
                      'l\'écran SOS.',
                      style: TextStyle(
                        color: AppColors.inactive,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (onRespond != null || isResponding) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRespond,
                  icon: Icon(
                    isResponding ? Icons.check_circle : Icons.volunteer_activism,
                    size: 18,
                  ),
                  label: Text(
                    isResponding ? 'VOUS ÊTES EN ROUTE' : 'JE RÉPONDS',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isResponding
                        ? Colors.green.shade700
                        : AppColors.sos,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.distressType});

  final DistressType distressType;

  @override
  Widget build(BuildContext context) {
    // Trois niveaux plutôt que deux: incendie et accident ne sont pas du même
    // calibre qu'« autre », mais moins immédiats que médical/agression.
    final color = distressType.isCritical
        ? AppColors.sos
        : switch (distressType) {
            DistressType.fire || DistressType.accident =>
              AppColors.secondaryText,
            _ => AppColors.inactive,
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        distressType.label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ResponderLine extends StatelessWidget {
  const _ResponderLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final hasResponders = count > 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            color: hasResponders ? Colors.green.shade700 : AppColors.inactive,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasResponders
                  ? '$count personne${count > 1 ? 's' : ''} en route'
                  : 'Personne ne s\'est encore manifesté',
              style: TextStyle(
                color: hasResponders ? Colors.green.shade800 : AppColors.inactive,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}