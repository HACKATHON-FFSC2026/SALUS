import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/auth/presentation/state/auth_state.dart';
import '../../domain/entities/emergency_numbers.dart';
import 'package:salus/core/entities/help_response_entity.dart';
import 'package:salus/core/entities/location_share_entity.dart';
import '../../domain/usecases/send_sos_usecase.dart';
import '../providers/responder_controller.dart';
import '../providers/sos_provider.dart';
import '../widgets/call_emergency_button.dart';
import '../widgets/cancel_sos_button.dart';
import '../widgets/sos_button.dart';
import '../widgets/sos_status_card.dart';

@RoutePage()
class SosPage extends ConsumerStatefulWidget {
  const SosPage({super.key});

  @override
  ConsumerState<SosPage> createState() => _SosPageState();
}

class _SosPageState extends ConsumerState<SosPage> {
  DistressType _distressType = DistressType.other;

  @override
  void initState() {
    super.initState();
    // La permission est demandée à l'arrivée sur la page, pas au moment du
    // maintien. Sinon le gesture aboutit à une boîte de dialogue système
    // puis à une erreur, alors que l'utilisateur vient de signaler une
    // détresse: si le dialogue est refusé ou la géolocalisation coupée,
    // aucune alerte n'est jamais envoyée.
    WidgetsBinding.instance.addPostFrameCallback((_) => requestLocationPermission());
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosControllerProvider);
    final auth = ref.watch(authProvider);

    // Un SOS est une action sensible: le spec impose une identité vérifiée.
    // Un invité n'a pas d'uid Firebase, l'écriture serait refusée.
    final canSend = auth.status == AuthStatus.authenticated && auth.user != null;

    ref.listen<SosState>(sosControllerProvider, (previous, next) {
      if (next.status == SosStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Erreur lors de l\'envoi'),
            backgroundColor: AppColors.sos,
          ),
        );
        ref.read(sosControllerProvider.notifier).resetFeedback();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              "Besoin d'aide ?",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: sosState.hasActiveAlert
            ? _ActiveSosView(alert: sosState.alert)
            : _SendSosView(
                canSend: canSend,
                isSending: sosState.status == SosStatus.sending,
                distressType: _distressType,
                onDistressTypeChanged: (type) =>
                    setState(() => _distressType = type),
                onSend: () => ref
                    .read(sosControllerProvider.notifier)
                    .triggerSos(distressType: _distressType),
              ),
      ),
    );
  }
}

/// Émission: type de détresse, bouton de maintien, numéros d'urgence.
class _SendSosView extends StatelessWidget {
  const _SendSosView({
    required this.canSend,
    required this.isSending,
    required this.distressType,
    required this.onDistressTypeChanged,
    required this.onSend,
  });

  final bool canSend;
  final bool isSending;
  final DistressType distressType;
  final ValueChanged<DistressType> onDistressTypeChanged;
  final VoidCallback onSend;

  static const _labels = {
    DistressType.medical: 'Médical',
    DistressType.security: 'Agression',
    DistressType.accident: 'Accident',
    DistressType.fire: 'Incendie',
    DistressType.other: 'Autre',
  };

  @override
  Widget build(BuildContext context) {
    // La page ne tient pas en hauteur sur un petit écran : bouton 240 px,
    // sélecteur de type, numéros d'urgence. `Spacer` débordait donc sur
    // petit écran. `minHeight` + `spaceEvenly` garde la répartition sur
    // grand écran tout en autorisant le défilement quand ça ne rentre pas.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                'SOS',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Votre position sera transmise aux secours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.inactive,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _DistressTypePicker(
                selected: distressType,
                labels: _labels,
                onChanged: onDistressTypeChanged,
              ),
              // L'envoi exige une identité vérifiable, mais l'écran ne masque
              // jamais les numéros d'urgence: un invité en détresse doit
              // pouvoir appeler quelqu'un même sans compte, et le compte
              // n'est pas l'urgence.
              if (!canSend) const _SignInHint(),
              SosButton(
                isLoading: isSending,
                isEnabled: canSend,
                onHold: onSend,
              ),
              CallEmergencyButton(
                numbers: EmergencyNumbers.forCountry('Madagascar'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alerte ouverte: suivi du statut et annulation.
class _ActiveSosView extends StatelessWidget {
  const _ActiveSosView({this.alert});

  final SOSAlert? alert;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isCancelling =
            ref.watch(sosControllerProvider.select((s) => s.status)) ==
            SosStatus.loading;
        final currentAlert = alert;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            SosStatusCard(alert: currentAlert),
            if (currentAlert != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Votre position est partagée en temps réel avec les '
                  'secouristes.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inactive,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _RespondersPanel(alert: currentAlert),
            ],
            const SizedBox(height: 28),
            CancelSosButton(
              isBusy: isCancelling,
              onConfirmCancel: () =>
                  ref.read(sosControllerProvider.notifier).cancelSos(),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

/// Intervenants proposés sur cette alerte.
///
/// Le compte vient des suivis actifs, pas de `responderIds`: ce registre est
/// figé par les règles (ajout seul) et garde trace des gens qui se sont
/// retirés. Aucun nom n'est affiché — les règles interdisent la lecture du
/// profil d'autrui, puisqu'il contient email et téléphone.
class _RespondersPanel extends ConsumerWidget {
  const _RespondersPanel({required this.alert});

  final SOSAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responders = ref.watch(respondersProvider(alert.id));
    final locations = ref.watch(responderLocationsProvider(alert.id));

    return responders.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        final locationByUid = locations.asData?.value ?? const {};
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
                Text(
                  items.isEmpty
                      ? 'Personne ne s\'est encore proposé'
                      : '${items.length} intervenant${items.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                for (final response in items)
                  _ResponderRow(
                    response: response,
                    share: locationByUid[response.responderId],
                    meters: distanceInMeters(
                      alert: alert,
                      location: locationByUid[response.responderId],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResponderRow extends StatelessWidget {
  const _ResponderRow({
    required this.response,
    required this.meters,
    required this.share,
  });

  final HelpResponse response;
  final double? meters;

  /// Position publiee par l'intervenant. Vaut `null` s'il n'a jamais partage,
  /// et porte `isActive: false` s'il a arrete: le point reste affiche, mais
  /// fige. Sans cette distinction la victime lit « 1.0 km » pour un
  /// intervenant dont le GPS est coupe, exactement comme pour un point vif.
  final LocationShare? share;

  static const _labels = {
    HelpResponseStatus.offered: 'A proposé son aide',
    HelpResponseStatus.enRoute: 'En route',
    HelpResponseStatus.arrived: 'Arrivé sur place',
    HelpResponseStatus.cancelled: 'Retiré',
  };

  @override
  Widget build(BuildContext context) {
    final onSite = response.status == HelpResponseStatus.arrived;
    // `null` n'est pas « figée »: c'est « jamais publié ». La mention ne
    // concerne que les cas où un point existe et a été figé.
    final isFrozen = share != null && !share!.isActive;
    final distance = meters == null
        ? 'position inconnue'
        : meters! < 950
        ? '${meters!.round()} m'
        : '${(meters! / 1000).toStringAsFixed(1)} km';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            onSite ? Icons.where_to_vote : Icons.directions_walk,
            size: 20,
            color: onSite ? Colors.green : AppColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labels[response.status] ?? 'En cours',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isFrozen ? '$distance (position figée)' : distance,
                  style: const TextStyle(color: AppColors.inactive, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistressTypePicker extends StatelessWidget {
  const _DistressTypePicker({
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  final DistressType selected;
  final Map<DistressType, String> labels;
  final ValueChanged<DistressType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final type in DistressType.values)
          ChoiceChip(
            label: Text(labels[type] ?? type.name),
            selected: type == selected,
            onSelected: (_) => onChanged(type),
          ),
      ],
    );
  }
}

/// Émission possible sans compte, envoi impossible. Invite à se connecter
/// au lieu de remplacer l'écran.
///
/// Le bouton d'envoi reste visible mais inerte : l'utilisateur voit ce qu'il
/// lui manque et ce qu'il peut faire dans l'intervalle — appeler un numéro
/// d'urgence, qui est la seule action qui compte quand on est en détresse.
class _SignInHint extends StatelessWidget {
  const _SignInHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.router.push(const LoginRoute()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connectez-vous pour envoyer un SOS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}