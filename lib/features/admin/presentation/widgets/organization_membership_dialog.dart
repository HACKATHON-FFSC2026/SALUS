import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';

class OrganizationMembershipDialog extends StatefulWidget {
  const OrganizationMembershipDialog({
    super.key,
    required this.user,
    required this.useCases,
    required this.onAssign,
    required this.onRemove,
  });

  final AdminPortalRecord user;
  final AdminPortalUseCases useCases;
  final Future<void> Function(String organizationId) onAssign;
  final Future<void> Function() onRemove;

  @override
  State<OrganizationMembershipDialog> createState() =>
      _OrganizationMembershipDialogState();
}

class _OrganizationMembershipDialogState
    extends State<OrganizationMembershipDialog> {
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Association impossible. Vérifiez que l’organisation est active et vérifiée.';
      });
    }
  }

  Future<void> _remove() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onRemove();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Impossible de retirer le rôle organisation.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Accès organisation'),
    content: SizedBox(
      width: 440,
      child: StreamBuilder<List<AdminPortalRecord>>(
        stream: widget.useCases.watchCollection(
          AdminCollection.organizations,
          admin: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'Impossible de charger la liste des organisations.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final organizations = snapshot.data!
              .where(
                (organization) =>
                    organization.verified && organization.isActive != false,
              )
              .toList();
          final currentId =
              organizations.any(
                (organization) => organization.id == widget.user.organizationId,
              )
              ? widget.user.organizationId
              : null;
          final selectedId =
              organizations.any(
                (organization) => organization.id == _selectedOrganizationId,
              )
              ? _selectedOrganizationId
              : currentId;

          if (organizations.isEmpty) {
            return const Text(
              'Aucune organisation active et vérifiée. Créez puis vérifiez une organisation avant de lui associer ce compte.',
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compte : ${widget.user.email ?? widget.user.title}',
                style: const TextStyle(color: AppColors.inactive),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(
                  labelText: 'Organisation',
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
              const SizedBox(height: 12),
              const Text(
                'Le rôle organizationMember sera ajouté au compte et son organisation associée. Son rôle citoyen sera conservé.',
                style: TextStyle(color: AppColors.inactive, fontSize: 12),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (widget.user.roles.contains('organizationMember')) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _saving ? null : _remove,
                  icon: const Icon(Icons.person_remove_alt_1),
                  label: const Text('Retirer l’accès organisation'),
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
                          : const Text('Associer'),
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
