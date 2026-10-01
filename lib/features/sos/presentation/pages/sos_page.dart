import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/auth/presentation/state/auth_state.dart';
import '../../domain/entities/emergency_numbers.dart';
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
    if (!canSend) return const _SignInPrompt();

    return Column(
      children: [
        const Spacer(),
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
            style: TextStyle(color: AppColors.inactive, fontSize: 15, height: 1.3),
          ),
        ),
        const SizedBox(height: 18),
        _DistressTypePicker(
          selected: distressType,
          labels: _labels,
          onChanged: onDistressTypeChanged,
        ),
        const Spacer(),
        SosButton(isLoading: isSending, isEnabled: true, onHold: onSend),
        const Spacer(),
        CallEmergencyButton(
          numbers: EmergencyNumbers.forCountry('Madagascar'),
        ),
        const SizedBox(height: 20),
      ],
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

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            SosStatusCard(alert: alert),
            if (alert != null) ...[
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

/// Identité non vérifiée: le spec veut la connexion avant l'action sensible,
/// pas un échec avec un message d'erreur après le maintien.
class _SignInPrompt extends ConsumerWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Identifiez-vous pour envoyer un SOS',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Un SOS engage des secours: votre identité doit être vérifiable '
              'pour qu\'ils sachent qui intervenir.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inactive),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.router.push(const LoginRoute()),
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text(
                'Se connecter',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (auth.warningMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.warningMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}