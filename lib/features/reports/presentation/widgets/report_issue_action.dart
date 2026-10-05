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
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.targetType == ReportTarget.road
          ? 'Signaler un incident routier'
          : 'Signaler un problème',
    ),
    content: Form(
      key: _formKey,
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.targetLocation != null) ...[
              const Text(
                'La position choisie sur la carte sera jointe à ce signalement.',
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<ReportReason>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Motif'),
              items: const [
                DropdownMenuItem(
                  value: ReportReason.unsafe,
                  child: Text('Dangereux'),
                ),
                DropdownMenuItem(
                  value: ReportReason.unavailable,
                  child: Text('Indisponible'),
                ),
                DropdownMenuItem(
                  value: ReportReason.blocked,
                  child: Text('Bloqué'),
                ),
                DropdownMenuItem(
                  value: ReportReason.other,
                  child: Text('Autre'),
                ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => _reason = value);
                    },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              maxLines: 4,
              maxLength: 4000,
              decoration: const InputDecoration(
                labelText: 'Précisions (facultatif)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value?.length ?? 0) > 4000
                  ? 'Maximum 4 000 caractères.'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        child: const Text('Annuler'),
      ),
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
  );
}
