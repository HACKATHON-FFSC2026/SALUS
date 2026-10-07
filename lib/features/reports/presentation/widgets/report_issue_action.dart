import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/reports/domain/models/report_submission.dart';
import 'package:salus/features/reports/presentation/providers/report_providers.dart';
import 'package:salus/features/reports/presentation/widgets/road_incident_location_picker.dart';

Future<void> showReportIssueDialog(
  BuildContext context, {
  required String reporterId,
  required ReportTarget targetType,
  required String targetId,
  ReportLocation? targetLocation,
  ReportReason initialReason = ReportReason.other,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReportIssueDialog(
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      targetLocation: targetLocation,
      initialReason: initialReason,
    ),
  );
}

class ReportIssueAction extends ConsumerWidget {
  const ReportIssueAction({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  final ReportTarget targetType;
  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    onPressed: () {
      final reporterId = ref.read(currentUidProvider);
      if (reporterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectez-vous pour envoyer un signalement.'),
          ),
        );
        return;
      }
      showReportIssueDialog(
        context,
        reporterId: reporterId,
        targetType: targetType,
        targetId: targetId,
      );
    },
    icon: const Icon(Icons.flag_outlined),
    label: const Text('Signaler un problème'),
  );
}

class RoadReportAction extends ConsumerWidget {
  const RoadReportAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FloatingActionButton.small(
        heroTag: 'report_road_fab',
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        tooltip: 'Signaler un incident routier',
        onPressed: () => launchRoadIncidentReport(context, ref),
        child: const Icon(Icons.report_problem_outlined),
      );
}

Future<void> launchRoadIncidentReport(
  BuildContext context,
  WidgetRef ref,
) async {
  final reporterId = ref.read(currentUidProvider);
  if (reporterId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connectez-vous pour signaler un incident routier.'),
      ),
    );
    return;
  }

  GeoPoint initialPosition;
  var gpsUnavailable = false;
  try {
    initialPosition = await ref.read(locationRepositoryProvider).currentPosition();
  } on LocationFailureException catch (error) {
    if (!context.mounted) return;
    gpsUnavailable = true;
    initialPosition = const GeoPoint(latitude: -18.8792, longitude: 47.5079);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'GPS indisponible : ${_locationFailureMessage(error.failure)} '
          'Vous pourrez placer le repère manuellement.',
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Impossible de récupérer la position GPS : $error'),
        backgroundColor: AppColors.sos,
      ),
    );
    return;
  }

  if (!context.mounted) return;
  final selectedLocation = await showRoadIncidentLocationPicker(
    context,
    initialLocation: initialPosition,
    gpsUnavailable: gpsUnavailable,
  );
  if (selectedLocation == null || !context.mounted) return;
  await showReportIssueDialog(
    context,
    reporterId: reporterId,
    targetType: ReportTarget.road,
    targetId: 'Position sélectionnée',
    targetLocation: ReportLocation(
      latitude: selectedLocation.latitude,
      longitude: selectedLocation.longitude,
    ),
    initialReason: ReportReason.blocked,
  );
}

String _locationFailureMessage(LocationFailure failure) => switch (failure) {
  LocationFailure.serviceDisabled =>
    'le service de localisation est désactivé.',
  LocationFailure.permissionDenied => 'permission de localisation refusée.',
  LocationFailure.permissionDeniedForever =>
    'permission de localisation bloquée dans les paramètres.',
  LocationFailure.timeout => 'aucun signal GPS.',
  LocationFailure.unknown => 'erreur de localisation.',
};

class _ReportIssueDialog extends ConsumerStatefulWidget {
  const _ReportIssueDialog({
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    this.targetLocation,
    required this.initialReason,
  });

  final String reporterId;
  final ReportTarget targetType;
  final String targetId;
  final ReportLocation? targetLocation;
  final ReportReason initialReason;

  @override
  ConsumerState<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends ConsumerState<_ReportIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late ReportReason _reason = widget.initialReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(submitReportUseCaseProvider)(
        reporterId: widget.reporterId,
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _reason,
        description: _descriptionController.text,
        targetLocation: widget.targetLocation,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Impossible d’envoyer le signalement : $error'),
          backgroundColor: AppColors.sos,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.sos.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.report_problem_outlined,
                        color: AppColors.sos,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.targetType == ReportTarget.road
                            ? 'Signaler un incident routier'
                            : 'Signaler un problème',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Annuler',
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (widget.targetLocation != null) ...[
                  const SizedBox(height: 4),
                  const _LocationNote(),
                ],
                const SizedBox(height: 18),
                const _FieldLabel('Motif'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final reason in ReportReason.values)
                      _ReasonChip(
                        reason: reason,
                        selected: _reason == reason,
                        enabled: !_isSubmitting,
                        onSelected: () => setState(() => _reason = reason),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Précisions (facultatif)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    hintText: 'Décrivez la situation…',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value?.length ?? 0) > 4000
                      ? 'Maximum 4 000 caractères.'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Envoyer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Titre de champ du formulaire de signalement.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    ),
  );
}

/// Rappel que la position choisie sur la carte est jointe au signalement.
class _LocationNote extends StatelessWidget {
  const _LocationNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.secondary.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.place_outlined, size: 18, color: AppColors.secondaryText),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'La position choisie sur la carte sera jointe à ce signalement.',
            style: TextStyle(fontSize: 12.5, color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

/// Motif du signalement, sélectionnable parmi quelques choix.
class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.reason,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ReportReason reason;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(_label(reason)),
    selected: selected,
    showCheckmark: false,
    onSelected: enabled ? (_) => onSelected() : null,
    labelStyle: TextStyle(
      fontWeight: FontWeight.w600,
      color: selected ? Colors.white : AppColors.primary,
    ),
    selectedColor: AppColors.primary,
    backgroundColor: AppColors.surface,
    side: BorderSide(
      color: selected
          ? AppColors.primary
          : AppColors.inactive.withValues(alpha: .3),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static String _label(ReportReason reason) => switch (reason) {
    ReportReason.unsafe => 'Dangereux',
    ReportReason.unavailable => 'Indisponible',
    ReportReason.blocked => 'Bloqué',
    ReportReason.other => 'Autre',
  };
}
