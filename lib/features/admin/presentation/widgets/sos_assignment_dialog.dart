import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';

class OrganizationAssignmentDialog extends StatefulWidget {
  const OrganizationAssignmentDialog({
    super.key,
    required this.title,
    required this.description,
    required this.currentOrganizationId,
    required this.confirmLabel,
    required this.useCases,
    required this.onAssign,
  });

  final String title;
  final String? description;
  final String? currentOrganizationId;
  final String confirmLabel;
  final AdminPortalUseCases useCases;
  final Future<void> Function(String organizationId) onAssign;

  @override
  State<OrganizationAssignmentDialog> createState() =>
      _OrganizationAssignmentDialogState();
}

class _OrganizationAssignmentDialogState
    extends State<OrganizationAssignmentDialog> {
  String? _selectedOrganizationId;
  bool _saving = false;
  String? _error;

  Future<void> _assign(String organizationId) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onAssign(organizationId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Affectation impossible : $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 440,
      child: StreamBuilder<List<AdminPortalRecord>>(
        stream: widget.useCases.watchCollection(
          AdminCollection.organizations,
          admin: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Impossible de charger les organisations.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final organizations =
              snapshot.data!
                  .where(
                    (organization) =>
                        organization.verified && organization.isActive == true,
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a.title.toLowerCase().compareTo(b.title.toLowerCase()),
                );
          final selectedId =
              organizations.any(
                (organization) => organization.id == _selectedOrganizationId,
              )
              ? _selectedOrganizationId
              : organizations.any(
                  (organization) =>
                      organization.id == widget.currentOrganizationId,
                )
              ? widget.currentOrganizationId
              : null;

          if (organizations.isEmpty) {
            return const Text(
              'Aucune organisation vérifiée et active ne peut recevoir ce SOS.',
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description?.trim().isNotEmpty == true
                    ? widget.description!.trim()
                    : 'Détail non renseigné',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.inactive),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(
                  labelText: 'Organisation responsable',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: [
                  for (final organization in organizations)
                    DropdownMenuItem(
                      value: organization.id,
                      child: Text(organization.title),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) =>
                          setState(() => _selectedOrganizationId = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: _saving || selectedId == null
                          ? null
                          : () => _assign(selectedId),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.confirmLabel),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
