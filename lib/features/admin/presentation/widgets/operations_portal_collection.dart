import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';
import 'package:salus/features/admin/presentation/widgets/operations_portal_data_row.dart';

class OperationsPortalCollection extends StatelessWidget {
  const OperationsPortalCollection({
    super.key,
    required this.collection,
    required this.isAdmin,
    required this.organizationId,
    required this.userId,
    required this.useCases,
    required this.onCreateOrganization,
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
                label: const Text('Tracer une zone à risque'),
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
          onEditRiskZone: onEditRiskZone,
        ),
      ],
    ),
  );
}

class OperationsPortalDataTable extends ConsumerWidget {
  const OperationsPortalDataTable({
    super.key,
    required this.title,
    required this.collection,
    required this.isAdmin,
    required this.organizationId,
    required this.userId,
    required this.useCases,
    required this.onEditRiskZone,
    this.limit,
  });

  final String title;
  final AdminCollection collection;
  final bool isAdmin;
  final String? organizationId;
  final String userId;
  final AdminPortalUseCases useCases;
  final ValueChanged<AdminPortalRecord> onEditRiskZone;
  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) => StreamBuilder(
    stream: useCases.watchCollection(
      collection,
      admin: isAdmin,
      organizationId: organizationId,
    ),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _PortalMessage(
          'Accès aux données refusé. Vérifiez les règles Firestore.',
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      var records = snapshot.data!;
      if (limit != null) records = records.take(limit!).toList();
      if (records.isEmpty) {
        return const _PortalMessage('Aucun élément à afficher pour le moment.');
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
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Divider(height: 1),
            for (final record in records)
              OperationsPortalDataRow(
                collection: collection,
                record: record,
                isAdmin: isAdmin,
                userId: userId,
                useCases: useCases,
                onEditRiskZone: onEditRiskZone,
              ),
          ],
        ),
      );
    },
  );
}

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
