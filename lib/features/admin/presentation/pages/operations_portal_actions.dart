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
