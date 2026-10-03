part of 'operations_portal_page.dart';

extension _OperationsPortalSections on _OperationsPortalPageState {
  Widget _content(String section, bool admin, String? orgId) {
    if (section == 'Vue générale') return _overview(admin, orgId);
    if (section == 'Organisations') {
      return _collectionPage(AdminCollection.organizations, admin, orgId);
    }
    if (section == 'Refuges') {
      return _collectionPage(AdminCollection.shelters, admin, orgId);
    }
    if (section == 'Utilisateurs') {
      return _collectionPage(AdminCollection.users, admin, orgId);
    }
    if (section == 'Signalements') {
      return _collectionPage(AdminCollection.reports, admin, orgId);
    }
    if (section == 'SOS') {
      return _collectionPage(AdminCollection.sosAlerts, admin, orgId);
    }
    return _collectionPage(AdminCollection.zones, admin, orgId);
  }

  Widget _collectionPage(
    AdminCollection collection,
    bool admin,
    String? orgId,
  ) => OperationsPortalCollection(
    collection: collection,
    isAdmin: admin,
    organizationId: orgId,
    userId: _uid,
    useCases: ref.read(adminPortalUseCasesProvider),
    onCreateOrganization: _createOrganization,
    onEditOrganization: _editOrganization,
    onManageOrganizationMembership: _manageOrganizationMembership,
    onViewReport: _viewReport,
    onCreateShelter: _createShelter,
    onCreateRiskZone: () => _openRiskZoneEditor(organizationId: orgId),
    onEditRiskZone: (zone) =>
        _openRiskZoneEditor(organizationId: orgId, zone: zone),
  );

  Widget _overview(bool admin, String? orgId) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue générale',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          admin
              ? 'Suivi des ressources et des équipes'
              : 'Suivi des interventions de votre organisation',
          style: const TextStyle(color: AppColors.inactive),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, box) {
            final count = box.maxWidth > 800
                ? 4
                : box.maxWidth > 500
                ? 2
                : 1;
            final names = admin
                ? [
                    'SOS en cours',
                    'Organisations',
                    'Refuges',
                    'Utilisateurs',
                    'Signalements ouverts',
                  ]
                : ['SOS en cours', 'Signalements ouverts', 'Zones actives'];
            final collections = admin
                ? const [
                    AdminCollection.sosAlerts,
                    AdminCollection.organizations,
                    AdminCollection.shelters,
                    AdminCollection.users,
                    AdminCollection.reports,
                  ]
                : const [
                    AdminCollection.sosAlerts,
                    AdminCollection.reports,
                    AdminCollection.zones,
                  ];
            return FutureBuilder<AdminDashboardMetrics>(
              future: ref
                  .read(adminPortalUseCasesProvider)
                  .loadMetrics(admin: admin),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Impossible de charger les indicateurs du dashboard.',
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  );
                }
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (var i = 0; i < names.length; i++)
                      SizedBox(
                        width: (box.maxWidth - 14 * (count - 1)) / count,
                        child: _metric(
                          names[i],
                          snapshot.data!.forCollection(collections[i]),
                          _metricIcon(i),
                          _metricColor(i),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        OperationsPortalDataTable(
          title: 'Dernières alertes',
          collection: AdminCollection.sosAlerts,
          isAdmin: admin,
          organizationId: orgId,
          userId: _uid,
          useCases: ref.read(adminPortalUseCasesProvider),
          limit: 6,
          onEditOrganization: (_) {},
          onManageOrganizationMembership: (_) {},
          onViewReport: (_) {},
          onEditRiskZone: (_) {},
        ),
        if (admin) ...[
          const SizedBox(height: 20),
          OperationsPortalDataTable(
            title: 'Signalements à traiter',
            collection: AdminCollection.reports,
            isAdmin: true,
            organizationId: orgId,
            userId: _uid,
            useCases: ref.read(adminPortalUseCasesProvider),
            limit: 5,
            onEditOrganization: (_) {},
            onManageOrganizationMembership: (_) {},
            onViewReport: _viewReport,
            onEditRiskZone: (_) {},
          ),
        ],
      ],
    ),
  );

  IconData _metricIcon(int i) => [
    Icons.sos,
    Icons.apartment,
    Icons.home_work,
    Icons.people,
    Icons.report_outlined,
  ][i % 5];
  Color _metricColor(int i) => [
    const Color(0xffc94b4b),
    AppColors.primary,
    AppColors.primary,
    AppColors.primary,
    const Color(0xffd97706),
  ][i % 5];

  Widget _metric(String title, int value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inactive,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
