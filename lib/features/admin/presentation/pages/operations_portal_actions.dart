part of 'operations_portal_page.dart';

extension _OperationsPortalActions on _OperationsPortalPageState {
  Future<void> _createShelter() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => AdminShelterFormDialog(
        onCreate:
            ({
              required name,
              required address,
              required capacityTotal,
              required latitude,
              required longitude,
              required resources,
            }) => ref
                .read(adminPortalUseCasesProvider)
                .createShelter(
                  name: name,
                  address: address,
                  capacityTotal: capacityTotal,
                  latitude: latitude,
                  longitude: longitude,
                  resources: resources,
                  userId: _uid,
                ),
      ),
    );
  }

  Future<void> _openRiskZoneEditor({
    String? organizationId,
    AdminPortalRecord? zone,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => OperationsPortalZoneEditor(
        zone: zone,
        onSave:
            ({
              required id,
              required name,
              required disasterType,
              required severity,
              required geometry,
            }) => ref
                .read(adminPortalUseCasesProvider)
                .saveManualRiskZone(
                  id: id,
                  name: name,
                  disasterType: disasterType,
                  severity: severity,
                  geometry: geometry,
                  userId: _uid,
                  organizationId: organizationId,
                ),
      ),
    );
  }

  Future<void> _createOrganization() async {
    await _openOrganizationEditor();
  }

  Future<void> _editOrganization(AdminPortalRecord record) async {
    await _openOrganizationEditor(record: record);
  }

  Future<void> _manageOrganizationMembership(AdminPortalRecord user) async {
    final useCases = ref.read(adminPortalUseCasesProvider);
    await showDialog<bool>(
      context: context,
      builder: (_) => OrganizationMembershipDialog(
        user: user,
        useCases: useCases,
        onAssign: (organizationId) =>
            useCases.assignUserToOrganization(user.id, organizationId),
        onRemove: () => useCases.removeUserOrganizationRole(user.id),
      ),
    );
  }

  Future<void> _viewReport(AdminPortalRecord report) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Signalement · ${_reportTargetLabel(report.targetType)}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _reportDetail('Statut', _reportStatusLabel(report.status)),
                _reportDetail('Motif', _reportReasonLabel(report.reason)),
                _reportDetail(
                  'Élément concerné',
                  report.targetId ?? 'Non précisé',
                ),
                _reportDetail('Auteur (UID)', report.reporterId ?? 'Inconnu'),
                _reportDetail('Date', _reportDate(report.createdAt)),
                const SizedBox(height: 8),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  report.description?.trim().isNotEmpty == true
                      ? report.description!.trim()
                      : 'Aucune description fournie.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _reportDetail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );

  Future<void> _openOrganizationEditor({AdminPortalRecord? record}) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => AdminOrganizationFormDialog(
        organization: record,
        onSave:
            ({
              required name,
              required type,
              required email,
              required phone,
            }) async {
              final useCases = ref.read(adminPortalUseCasesProvider);
              if (record == null) {
                await useCases.createOrganization(
                  name: name,
                  type: type,
                  email: email,
                  phone: phone,
                );
              } else {
                await useCases.updateOrganization(
                  id: record.id,
                  name: name,
                  type: type,
                  email: email,
                  phone: phone,
                );
              }
            },
      ),
    );
  }
}

String _reportTargetLabel(String? value) => switch (value) {
  'shelter' => 'Refuge',
  'zone' => 'Zone',
  'road' => 'Route',
  'other' => 'Autre élément',
  _ => 'Élément inconnu',
};

String _reportReasonLabel(String? value) => switch (value) {
  'unsafe' => 'Dangereux',
  'unavailable' => 'Indisponible',
  'blocked' => 'Bloqué',
  'other' => 'Autre motif',
  _ => 'Motif inconnu',
};

String _reportStatusLabel(String? value) => switch (value) {
  'open' => 'Ouvert',
  'reviewed' => 'Examiné',
  'resolved' => 'Résolu',
  _ => value ?? 'Inconnu',
};

String _reportDate(DateTime? value) => value == null
    ? 'Inconnue'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
