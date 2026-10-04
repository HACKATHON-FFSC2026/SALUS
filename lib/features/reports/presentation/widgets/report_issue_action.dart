import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/reports/domain/models/report_submission.dart';
import 'package:salus/features/reports/presentation/providers/report_providers.dart';

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
      showDialog<void>(
        context: context,
        builder: (_) => _ReportIssueDialog(
          reporterId: reporterId,
          targetType: targetType,
          targetId: targetId,
        ),
      );
    },
    icon: const Icon(Icons.flag_outlined),
    label: const Text('Signaler un problème'),
  );
}

class _ReportIssueDialog extends ConsumerStatefulWidget {
  const _ReportIssueDialog({
    required this.reporterId,
    required this.targetType,
    required this.targetId,
  });

  final String reporterId;
  final ReportTarget targetType;
  final String targetId;

  @override
  ConsumerState<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends ConsumerState<_ReportIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ReportReason _reason = ReportReason.other;
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
    title: const Text('Signaler un problème'),
    content: Form(
      key: _formKey,
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
