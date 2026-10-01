import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';

class AdminOrganizationFormDialog extends StatefulWidget {
  const AdminOrganizationFormDialog({
    super.key,
    this.organization,
    required this.onSave,
  });

  final AdminPortalRecord? organization;
  final Future<void> Function({
    required String name,
    required String type,
    required String email,
    required String phone,
  })
  onSave;

  @override
  State<AdminOrganizationFormDialog> createState() =>
      _AdminOrganizationFormDialogState();
}

class _AdminOrganizationFormDialogState
    extends State<AdminOrganizationFormDialog> {
  static const _types = {
    'ngo': 'ONG',
    'government': 'Administration publique',
    'emergencyServices': 'Services d’urgence',
    'other': 'Autre',
  };

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.organization?.name ?? '',
  );
  late final _email = TextEditingController(
    text: widget.organization?.contactEmail ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.organization?.contactPhone ?? '',
  );
  late String _type = _types.containsKey(widget.organization?.type)
      ? widget.organization!.type!
      : 'ngo';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        name: _name.text.trim(),
        type: _type,
        email: _email.text.trim(),
        phone: _phone.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Enregistrement impossible. Vérifiez votre connexion puis réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.organization != null;
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 650,
        height: screen.height * .82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing
                              ? 'Modifier l’organisation'
                              : 'Ajouter une organisation',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Renseignez la fiche et les coordonnées de contact.',
                          style: TextStyle(
                            color: AppColors.inactive,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _OrganizationSection(
                      title: 'Identité de l’organisation',
                      subtitle:
                          'Ces informations apparaissent dans le portail et les fiches de contact.',
                      icon: Icons.badge_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            enabled: !_saving,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nom officiel',
                              hintText: 'Ex. Protection Civile',
                              prefixIcon: Icon(Icons.apartment_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Le nom de l’organisation est obligatoire.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: 'Type d’organisation',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: [
                              for (final entry in _types.entries)
                                DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _type = value);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    _OrganizationSection(
                      title: 'Coordonnées de contact',
                      subtitle:
                          'Indiquez un email et un numéro que les équipes peuvent joindre.',
                      icon: Icons.contact_mail_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _email,
                            enabled: !_saving,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email de contact',
                              hintText: 'contact@organisation.org',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty || !email.contains('@')) {
                                return 'Saisissez une adresse email valide.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phone,
                            enabled: !_saving,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone de contact',
                              hintText: '+261 …',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Le téléphone de contact est obligatoire.'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    _statusCard(context),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(editing ? Icons.save_outlined : Icons.add),
                    label: Text(
                      editing ? 'Enregistrer' : 'Créer l’organisation',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(BuildContext context) {
    final organization = widget.organization;
    final verified = organization?.verified ?? false;
    final active = organization?.isActive != false;
    final createdAt = organization?.createdAt;
    return _OrganizationSection(
      title: 'Statut et suivi',
      subtitle:
          'Les dates de création et de validation sont gérées automatiquement.',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: active ? 'Active' : 'Suspendue',
                active: active,
              ),
              _StatusChip(
                label: verified ? 'Vérifiée' : 'À vérifier',
                active: verified,
              ),
            ],
          ),
          if (createdAt != null || organization?.verifiedBy != null) ...[
            const SizedBox(height: 12),
            if (createdAt != null)
              Text(
                'Créée le ${_formatDate(createdAt)}',
                style: const TextStyle(color: AppColors.inactive, fontSize: 12),
              ),
            if (organization?.verifiedBy != null)
              Text(
                'Vérifiée par ${organization!.verifiedBy} le ${_formatDate(organization.verifiedAt)}',
                style: const TextStyle(color: AppColors.inactive, fontSize: 12),
              ),
          ],
          const SizedBox(height: 8),
          const Text(
            'La vérification et la suspension se gèrent depuis les actions de la fiche organisation.',
            style: TextStyle(color: AppColors.inactive, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OrganizationSection extends StatelessWidget {
  const _OrganizationSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surface,
    elevation: 1,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.inactive, fontSize: 12),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: (active ? AppColors.secondary : AppColors.inactive).withValues(
        alpha: .12,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? AppColors.primary : AppColors.inactive,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return 'date inconnue';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
