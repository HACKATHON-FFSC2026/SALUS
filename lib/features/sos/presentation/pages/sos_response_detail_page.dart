import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/core/entities/help_response_entity.dart';
import 'package:salus/features/sos/presentation/providers/responder_controller.dart';
import 'package:salus/core/utils/external_navigation.dart';
import '../distress_label.dart';
import '../../domain/entities/first_aid_guidelines.dart';

/// Fiche d'intervention affichée après « JE RÉPONDS ».
///
/// Elle porte deux choses: où aller, et quoi faire en attendant. Les consignes
/// viennent de [FirstAidGuideline], donc dépendantes du type de détresse
/// annoncé, pas d'une liste générique identique pour un incendie et pour une
/// agression.
///
/// Elle pilote en plus le suivi du côté intervenant: la position_partagée vers la
/// victime, l'annonce d'arrivée, et le retrait. Le `responseId` n'est pas passé
/// en argument de route — le suivi est retrouvé en filtrant les réponses de
/// l'alerte sur son propre `responderId`, ce qui évite de régénérer le
/// routeur et reste correct après un hot restart.
@RoutePage()
class SosResponseDetailPage extends ConsumerStatefulWidget {
  const SosResponseDetailPage({super.key, required this.sosAlert});

  final SOSAlert sosAlert;

  @override
  ConsumerState<SosResponseDetailPage> createState() =>
      _SosResponseDetailPageState();
}

class _SosResponseDetailPageState extends ConsumerState<SosResponseDetailPage> {
  HelpResponse? _myResponse;

  SOSAlert get alert => widget.sosAlert;

  @override
  void initState() {
    super.initState();
    // Partage la position dès l'ouverture: la victime a choisi d'afficher son
    // itinéraire, elle doit voir l'intervenant bouger.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(responderControllerProvider.notifier)
          .startSharing(alertId: alert.id);
    });
  }

  Future<void> _openMaps(BuildContext context) => openExternalDirections(
    context,
    latitude: alert.location.latitude,
    longitude: alert.location.longitude,
    label: alert.distressType.label,
    travelMode: 'driving',
  );

  Future<void> _markArrived() async {
    final response = _myResponse;
    if (response == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(responderControllerProvider.notifier)
        .markArrived(responseId: response.id);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Arrivée signalée. La victime sait que vous êtes là.'),
      ),
    );
  }

  /// Le refus de permission n'avait aucune porte de sortie: l'intervenant
  /// restait « en route » sans que la victime voie sa position. On propose
  /// d'autoriser, ou d'aller aux réglages si c'est définitivement refusé.
  Future<void> _retryLocationSharing() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    await ref
        .read(responderControllerProvider.notifier)
        .startSharing(alertId: alert.id);
  }

  Future<void> _withdraw() async {
    final response = _myResponse;
    if (response == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se retirer ?'),
        content: const Text(
          'La victime ne comptera plus votre intervention. Vous pouvez '
          'répondre à nouveau tant que l\'alerte est active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se retirer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(responderControllerProvider.notifier)
        .withdraw(responseId: response.id);
    if (!mounted) return;
    context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final guideline = FirstAidGuideline.getGuidelinesFor(
      alert.distressType,
    );
    final controller = ref.watch(responderControllerProvider);
    final myUid = ref.watch(currentUidProvider);
    // On se suit soi-même: la liste des intervenants sert aussi à retrouver
    // son document de suivi après un redémarrage de l'app.
    ref.listen(respondersProvider(alert.id), (_, next) {
      final mine = next.asData?.value
          .where((r) => r.responderId == myUid)
          .firstOrNull;
      if (mine != null && mine.id != _myResponse?.id) {
        setState(() => _myResponse = mine);
      }
    });

    final withdrawn = _myResponse?.status == HelpResponseStatus.cancelled;
    final arrived = _myResponse?.status == HelpResponseStatus.arrived;

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
            _Acknowledgement(
              status: controller.status,
              isSharingLocation: controller.isSharingLocation,
              withdrawn: withdrawn,
              warning: controller.errorMessage,
              onRetryLocation: _retryLocationSharing,
            ),
            const SizedBox(height: 16),
            _SummaryCard(alert: alert),
            const SizedBox(height: 16),
            // L'action principale d'un intervenant est d'aller sur place:
            // elle passe avant la liste de consignes, qui peut être longue.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
            ),
            const SizedBox(height: 24),
            Text(
              guideline.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final (index, step) in guideline.steps.indexed)
              _Step(index: index + 1, text: step),
            const SizedBox(height: 28),
            if (!withdrawn) ...[
              if (arrived)
                // État, pas bouton: repartir de « à venir » après une arrivée
                // annoncée ferait retomber la victime dans l'attente.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade700, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.where_to_vote, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Arrivée signalée. Vous êtes sur place.',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _myResponse == null ? null : _markArrived,
                  icon: const Icon(Icons.where_to_vote, color: AppColors.primary),
                  label: const Text('JE SUIS ARRIVÉ(E) SUR PLACE'),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _myResponse == null ? null : _withdraw,
                icon: const Icon(Icons.undo, color: AppColors.inactive),
                label: Text(
                  arrived ? 'Me retirer (appui par erreur ?)' : 'Je ne peux plus venir',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Acknowledgement extends StatelessWidget {
  const _Acknowledgement({
    required this.status,
    required this.isSharingLocation,
    required this.withdrawn,
    this.warning,
    this.onRetryLocation,
  });

  final ResponderStatus status;
  final bool isSharingLocation;
  final bool withdrawn;
  final String? warning;

  /// Relance le partage ou ouvre les réglages. Null seulement si l'action
  /// n'est pas pertinente dans le contexte courant.
  final VoidCallback? onRetryLocation;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, title, detail) = switch (status) {
      ResponderStatus.arrived => (
          Icons.pin_drop,
          Colors.green,
          'Vous êtes arrivé sur place',
          'Prévenez la victime par appel: elle sait où vous êtes.',
        ),
      ResponderStatus.cancelled => (
          Icons.undo,
          AppColors.inactive,
          'Vous vous êtes retiré',
          'La victime ne compte plus votre intervention.',
        ),
      ResponderStatus.failure => (
          Icons.error_outline,
          AppColors.sos,
          'Suivi indisponible',
          warning ?? 'La position et l\'arrivée n\'ont pas pu être signalées.',
        ),
      _ => isSharingLocation
          ? (
              Icons.my_location,
              Colors.green,
              'Vous avez répondu à cet appel',
              'Votre position est partagée à la victime en direct.',
            )
          : (
              Icons.notifications_active_outlined,
              AppColors.primary,
              'Vous avez répondu à cet appel',
              warning ??
                  'Partage de position indisponible: signalez votre arrivée à la main.',
            ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(color: AppColors.inactive, fontSize: 12),
                ),
                if (onRetryLocation != null &&
                    !isSharingLocation &&
                    !withdrawn) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: onRetryLocation,
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: const Text('Autoriser la localisation'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
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
                    alert.distressType.label.toUpperCase(),
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
                      color: AppColors.secondaryText,
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
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Numérotée: des consignes de premiers secours sont une séquence, pas une
    // liste à puces sans ordre.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}