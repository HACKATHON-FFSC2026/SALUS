import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';

class OperationsPortalDataRow extends StatelessWidget {
  const OperationsPortalDataRow({
    super.key,
    required this.collection,
    required this.record,
    required this.isAdmin,
    required this.userId,
    required this.useCases,
    required this.onEditRiskZone,
  });

  final AdminCollection collection;
  final AdminPortalRecord record;
  final bool isAdmin;
  final String userId;
  final AdminPortalUseCases useCases;
  final ValueChanged<AdminPortalRecord> onEditRiskZone;

  String get _detail => switch (collection) {
    AdminCollection.sosAlerts =>
      '${record.distressType ?? 'urgence'} · ${_displayDate(record.createdAt)}',
    AdminCollection.users =>
      '${record.email ?? ''} · ${record.roles.join(', ')}',
    AdminCollection.shelters =>
      '${record.address ?? ''} · ${record.capacityOccupied ?? 0}/${record.capacityTotal ?? 0} places',
    AdminCollection.organizations =>
      '${record.contactEmail ?? ''} · ${record.type ?? ''}',
    AdminCollection.zones =>
      '${_disasterLabel(record.disasterType)} · ${_severityLabel(record.severity)} · ${record.geometry.length} points',
    _ =>
      '${record.targetType ?? record.type ?? ''} · ${_displayDate(record.createdAt ?? record.startedAt)}',
  };

  String get _status => collection == AdminCollection.zones
      ? (record.isActive == false ? 'inactive' : 'active')
      : collection == AdminCollection.shelters
      ? record.validationStatus ?? 'pending'
      : record.status ??
            (record.verified
                ? 'vérifiée'
                : collection == AdminCollection.organizations
                ? 'à vérifier'
                : record.validationStatus ?? 'actif');

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.inactive),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PortalStatusPill(_status),
        if (isAdmin &&
            collection == AdminCollection.organizations &&
            !record.verified)
          IconButton(
            tooltip: 'Vérifier',
            onPressed: () => useCases.verifyOrganization(record.id, userId),
            icon: const Icon(Icons.verified_outlined, color: AppColors.primary),
          ),
        if (collection == AdminCollection.sosAlerts &&
            record.status != 'resolved' &&
            record.status != 'cancelled')
          IconButton(
            tooltip: 'Prendre en charge / résoudre',
            onPressed: () => useCases.updateSos(
              id: record.id,
              currentStatus: record.status,
              assignedOrganizationId: record.assignedOrganizationId,
              uid: userId,
            ),
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.primary,
            ),
          ),
        if (isAdmin && collection == AdminCollection.shelters)
          PopupMenuButton<String>(
            tooltip: 'Changer le statut',
            initialValue: record.validationStatus ?? 'pending',
            onSelected: (status) =>
                useCases.setShelterValidationStatus(record.id, status, userId),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'validated', child: Text('Validé')),
              PopupMenuItem(value: 'pending', child: Text('En attente')),
              PopupMenuItem(value: 'rejected', child: Text('Rejeté')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.edit_outlined, color: AppColors.primary),
            ),
          ),
        if (collection == AdminCollection.zones &&
            (isAdmin || record.createdBy == userId))
          IconButton(
            tooltip: record.isActive == true
                ? 'Désactiver la zone'
                : 'Réactiver la zone',
            onPressed: () => useCases.toggleZone(
              record.id,
              isActive: record.isActive != true,
            ),
            icon: Icon(
              record.isActive == true
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.inactive,
            ),
          ),
        if (collection == AdminCollection.zones &&
            record.zoneType == 'risk' &&
            record.zoneOrigin == 'manual' &&
            (isAdmin || record.createdBy == userId))
          IconButton(
            tooltip: 'Modifier le périmètre',
            onPressed: () => onEditRiskZone(record),
            icon: const Icon(Icons.edit_location_alt_outlined),
          ),
        if (isAdmin && collection == AdminCollection.users)
          IconButton(
            tooltip: record.isActive == false
                ? 'Réactiver le compte'
                : 'Désactiver le compte',
            onPressed: () => useCases.setUserActive(
              record.id,
              isActive: record.isActive == false,
            ),
            icon: Icon(
              record.isActive == false
                  ? Icons.person_add_alt
                  : Icons.person_off_outlined,
              color: AppColors.inactive,
            ),
          ),
      ],
    ),
  );
}

String _disasterLabel(String? value) => switch (value) {
  'flood' => 'Inondation',
  'cyclone' => 'Cyclone',
  'landslide' => 'Glissement de terrain',
  'earthquake' => 'Séisme',
  'tsunami' => 'Tsunami',
  'volcano' => 'Éruption volcanique',
  _ => 'Risque',
};

String _severityLabel(String? value) => switch (value) {
  'low' => 'Faible',
  'medium' => 'Modérée',
  'high' => 'Élevée',
  'critical' => 'Critique',
  _ => 'Gravité inconnue',
};

String _displayDate(DateTime? value) => value == null
    ? ''
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

class _PortalStatusPill extends StatelessWidget {
  const _PortalStatusPill(this.value);

  final String value;

  static const _labels = {
    'waiting': 'En attente',
    'inProgress': 'En cours',
    'resolved': 'Résolue',
    'cancelled': 'Annulée',
    'pending': 'En attente',
    'validated': 'Validé',
    'open': 'Ouvert',
    'reviewed': 'Examiné',
    'verified': 'Vérifiée',
    'rejected': 'Rejeté',
    'active': 'Active',
    'inactive': 'Inactive',
  };

  @override
  Widget build(BuildContext context) {
    final active = [
      'waiting',
      'pending',
      'open',
      'inProgress',
      'active',
    ].contains(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? AppColors.secondary.withValues(alpha: .16)
            : AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labels[value] ?? value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
