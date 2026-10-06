import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record_filter.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';
import 'package:salus/features/admin/presentation/widgets/operations_portal_data_row.dart';
import 'package:salus/features/admin/presentation/widgets/assigned_road_reports_map.dart';

class OperationsPortalCollection extends StatelessWidget {
  const OperationsPortalCollection({
    super.key,
    required this.collection,
    required this.isAdmin,
    required this.organizationId,
    required this.userId,
    required this.useCases,
    required this.onCreateOrganization,
    required this.onEditOrganization,
    required this.onManageOrganizationMembership,
    required this.onViewReport,
    required this.onCreateShelter,
    required this.onCreateRiskZone,
    required this.onEditRiskZone,
  });

  final AdminCollection collection;
  final bool isAdmin;
  final String? organizationId;
  final String userId;
  final AdminPortalUseCases useCases;
  final VoidCallback onCreateOrganization;
  final ValueChanged<AdminPortalRecord> onEditOrganization;
  final ValueChanged<AdminPortalRecord> onManageOrganizationMembership;
  final ValueChanged<AdminPortalRecord> onViewReport;
  final VoidCallback onCreateShelter;
  final VoidCallback onCreateRiskZone;
  final ValueChanged<AdminPortalRecord> onEditRiskZone;

  String get _title => switch (collection) {
    AdminCollection.organizations => 'Organisations',
    AdminCollection.shelters => 'Refuges',
    AdminCollection.users => 'Utilisateurs',
    AdminCollection.sosAlerts => 'Alertes de détresse',
    AdminCollection.reports => 'Signalements',
    AdminCollection.zones => 'Zones de sécurité',
  };

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Données synchronisées en temps réel',
                style: TextStyle(color: AppColors.inactive),
              ),
            ),
            if (isAdmin && collection == AdminCollection.organizations)
              FilledButton.icon(
                onPressed: onCreateOrganization,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            if (isAdmin && collection == AdminCollection.shelters)
              FilledButton.icon(
                onPressed: onCreateShelter,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un refuge'),
              ),
            if (collection == AdminCollection.zones)
              FilledButton.icon(
                onPressed: onCreateRiskZone,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Créer une alerte / zone à risque'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        OperationsPortalDataTable(
          title: _title,
          collection: collection,
          isAdmin: isAdmin,
          organizationId: organizationId,
          userId: userId,
          useCases: useCases,
          onEditOrganization: onEditOrganization,
          onManageOrganizationMembership: onManageOrganizationMembership,
          onViewReport: onViewReport,
          onEditRiskZone: onEditRiskZone,
        ),
      ],
    ),
  );
}

class OperationsPortalDataTable extends StatefulWidget {
  const OperationsPortalDataTable({
    super.key,
    required this.title,
    required this.collection,
    required this.isAdmin,
    required this.organizationId,
    required this.userId,
    required this.useCases,
    required this.onEditOrganization,
    required this.onManageOrganizationMembership,
    required this.onViewReport,
    required this.onEditRiskZone,
    this.limit,
  });

  final String title;
  final AdminCollection collection;
  final bool isAdmin;
  final String? organizationId;
  final String userId;
  final AdminPortalUseCases useCases;
  final ValueChanged<AdminPortalRecord> onEditOrganization;
  final ValueChanged<AdminPortalRecord> onManageOrganizationMembership;
  final ValueChanged<AdminPortalRecord> onViewReport;
  final ValueChanged<AdminPortalRecord> onEditRiskZone;
  final int? limit;

  @override
  State<OperationsPortalDataTable> createState() =>
      _OperationsPortalDataTableState();
}

class _OperationsPortalDataTableState extends State<OperationsPortalDataTable> {
  final _searchController = TextEditingController();
  String? _status;
  DateTimeRange? _dateRange;
  bool _newestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chooseDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
      helpText: 'Filtrer par période',
      saveText: 'Appliquer',
      cancelText: 'Annuler',
      confirmText: 'Appliquer',
    );
    if (range != null && mounted) setState(() => _dateRange = range);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: widget.useCases.watchCollection(
      widget.collection,
      admin: widget.isAdmin,
      organizationId: widget.organizationId,
    ),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _PortalMessage(_portalReadError(snapshot.error));
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final allRecords = snapshot.data!;
      final availableStatuses = allRecords
          .map((record) => adminRecordStatus(widget.collection, record))
          .toSet()
          .toList()
        ..sort();
      var records = filterAdminRecords(
        collection: widget.collection,
        records: allRecords,
        query: _searchController.text,
        status: _status,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        newestFirst: _newestFirst,
      );
      if (widget.limit != null) {
        records = records.take(widget.limit!).toList();
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (widget.limit == null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: _buildFilters(availableStatuses),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  '${records.length} résultat${records.length == 1 ? '' : 's'}'
                  ' sur ${allRecords.length}',
                  style: const TextStyle(
                    color: AppColors.inactive,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const Divider(height: 1),
            if (records.isEmpty)
              _PortalMessage(
                allRecords.isEmpty
                    ? _emptyCollectionMessage(widget.collection, widget.isAdmin)
                    : 'Aucun résultat ne correspond à ces filtres.',
              )
            else ...[
              if (widget.collection == AdminCollection.reports)
                AssignedRoadReportsMap(
                  reports: records,
                  onTapReport: widget.onViewReport,
                ),
              for (final record in records)
                OperationsPortalDataRow(
                  collection: widget.collection,
                  record: record,
                  isAdmin: widget.isAdmin,
                  organizationId: widget.organizationId,
                  userId: widget.userId,
                  useCases: widget.useCases,
                  onEditOrganization: widget.onEditOrganization,
                  onManageOrganizationMembership:
                      widget.onManageOrganizationMembership,
                  onViewReport: widget.onViewReport,
                  onEditRiskZone: widget.onEditRiskZone,
                ),
            ],
          ],
        ),
      );
    },
  );

  Widget _buildFilters(List<String> statuses) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      final search = SizedBox(
        width: compact ? double.infinity : 280,
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _searchHint(widget.collection),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer la recherche',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      );
      final status = SizedBox(
        width: compact ? double.infinity : 190,
        child: DropdownButtonFormField<String?>(
          key: ValueKey('${widget.collection}-${_status ?? 'all'}'),
          initialValue: _status,
          decoration: const InputDecoration(
            labelText: 'Statut',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tous les statuts'),
            ),
            for (final value in statuses)
              DropdownMenuItem<String?>(
                value: value,
                child: Text(_adminStatusLabel(value)),
              ),
          ],
          onChanged: (value) => setState(() => _status = value),
        ),
      );
      final date = OutlinedButton.icon(
        onPressed: _chooseDateRange,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(
          _dateRange == null
              ? 'Toutes les dates'
              : '${_formatDate(_dateRange!.start)} – ${_formatDate(_dateRange!.end)}',
        ),
      );
      final sort = OutlinedButton.icon(
        onPressed: () => setState(() => _newestFirst = !_newestFirst),
        icon: Icon(
          _newestFirst ? Icons.south : Icons.north,
        ),
        label: Text(_newestFirst ? 'Plus récent' : 'Plus ancien'),
      );
      final clear = TextButton.icon(
        onPressed: _searchController.text.isEmpty &&
                _status == null &&
                _dateRange == null &&
                _newestFirst
            ? null
            : () {
                _searchController.clear();
                setState(() {
                  _status = null;
                  _dateRange = null;
                  _newestFirst = true;
                });
              },
        icon: const Icon(Icons.filter_alt_off_outlined),
        label: const Text('Réinitialiser'),
      );

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          search,
          status,
          date,
          sort,
          clear,
        ],
      );
    },
  );
}

String _emptyCollectionMessage(AdminCollection collection, bool isAdmin) =>
    !isAdmin
    ? switch (collection) {
        AdminCollection.sosAlerts =>
          'Aucun SOS n’est affecté à votre organisation.',
        AdminCollection.reports =>
          'Aucun signalement n’est affecté à votre organisation.',
        AdminCollection.shelters =>
          'Aucune proposition de refuge n’est affectée à votre organisation.',
        _ => 'Aucun élément à afficher pour le moment.',
      }
    : 'Aucun élément à afficher pour le moment.';

String _searchHint(AdminCollection collection) => switch (collection) {
  AdminCollection.organizations => 'Rechercher une organisation…',
  AdminCollection.shelters => 'Rechercher un refuge…',
  AdminCollection.users => 'Nom, email, rôle ou ID…',
  AdminCollection.sosAlerts => 'ID, type, statut ou organisation…',
  AdminCollection.reports => 'ID, motif, cible ou organisation…',
  AdminCollection.zones => 'Nom, type, source ou gravité…',
};

String _adminStatusLabel(String status) => switch (status) {
  'waiting' => 'En attente',
  'assigned' => 'Assigné',
  'inProgress' => 'En cours',
  'resolved' => 'Résolu',
  'cancelled' => 'Annulé',
  'pending' => 'À vérifier',
  'validated' => 'Validé',
  'rejected' => 'Rejeté',
  'open' => 'Ouvert',
  'reviewed' => 'Examiné',
  'verified' => 'Vérifié',
  'active' => 'Actif',
  'inactive' => 'Inactif',
  'closed' => 'Clôturé',
  'suspended' => 'Suspendu',
  'unknown' => 'Inconnu',
  _ => status,
};

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

class _PortalMessage extends StatelessWidget {
  const _PortalMessage(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.inactive),
    ),
  );
}

String _portalReadError(Object? error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Accès refusé. Vérifiez le rôle de ce compte auprès d’un administrateur.',
      'failed-precondition' =>
        'Données non disponibles pour le moment. Réessayez plus tard.',
      'unavailable' =>
        'Connexion indisponible. Vérifiez votre réseau puis réessayez.',
      _ => 'Impossible de charger les données. Réessayez plus tard.',
    };
  }
  return 'Impossible de charger les données. Réessayez plus tard.';
}
