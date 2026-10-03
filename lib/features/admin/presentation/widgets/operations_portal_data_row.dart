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
    required this.organizationId,
    required this.userId,
    required this.useCases,
    required this.onEditOrganization,
    required this.onManageOrganizationMembership,
    required this.onViewReport,
    required this.onEditRiskZone,
  });

  final AdminCollection collection;
  final AdminPortalRecord record;
  final bool isAdmin;
  final String? organizationId;
  final String userId;
  final AdminPortalUseCases useCases;
  final ValueChanged<AdminPortalRecord> onEditOrganization;
  final ValueChanged<AdminPortalRecord> onManageOrganizationMembership;
  final ValueChanged<AdminPortalRecord> onViewReport;
  final ValueChanged<AdminPortalRecord> onEditRiskZone;

  String get _title => switch (collection) {
    AdminCollection.sosAlerts =>
      'SOS · ${_shortCode(record.userId ?? record.id)}',
    AdminCollection.users =>
      record.displayName ?? 'Utilisateur ${_shortCode(record.id)}',
    AdminCollection.reports => 'Signalement · ${_shortCode(record.id)}',
    _ => record.title,
  };

  String get _detail => switch (collection) {
    AdminCollection.sosAlerts =>
      '${_distressLabel(record.distressType)} · ${record.responderCount} aidant${record.responderCount == 1 ? '' : 's'} · ${record.description ?? 'Aucun détail'} · ${_displayDate(record.createdAt)}',
    AdminCollection.users =>
      '${record.email ?? 'Email non renseigné'} · ${_rolesLabel(record.roles)} · ${_safetyStatusLabel(record.safetyStatus)}',
    AdminCollection.shelters =>
      '${record.address ?? 'Adresse non renseignée'} · ${_shelterStatusLabel(record.status)} · ${record.capacityOccupied ?? 0}/${record.capacityTotal ?? 0} places',
    AdminCollection.organizations =>
      '${record.contactEmail ?? 'Email non renseigné'} · ${record.contactPhone ?? 'Téléphone non renseigné'} · ${_organizationType(record.type)}',
    AdminCollection.reports =>
      '${_reportReason(record.reason)} · ${_reportTarget(record.targetType)} · ${_shortCode(record.targetId ?? '')} · ${_displayDate(record.createdAt)}',
    AdminCollection.zones => _zoneDetail(record),
  };

  String get _status => switch (collection) {
    AdminCollection.zones =>
      record.zoneType == 'risk' && record.zoneOrigin == 'manual'
          ? record.isActive == false
                ? 'closed'
                : 'active'
          : record.isActive == false
          ? 'inactive'
          : 'active',
    AdminCollection.shelters => record.validationStatus ?? 'pending',
    AdminCollection.organizations =>
      record.isActive != true
          ? 'suspended'
          : record.verified
          ? 'verified'
          : 'pending',
    AdminCollection.users => record.isActive == false ? 'inactive' : 'active',
    AdminCollection.sosAlerts ||
    AdminCollection.reports => record.status ?? 'unknown',
  };

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
                _title,
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
        if (isAdmin && collection == AdminCollection.organizations) ...[
          IconButton(
            tooltip: 'Modifier l’organisation',
            onPressed: () => onEditOrganization(record),
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),
          IconButton(
            tooltip: record.isActive != true
                ? 'Réactiver l’organisation'
                : 'Suspendre l’organisation',
            onPressed: () => useCases.setOrganizationActive(
              record.id,
              isActive: record.isActive != true,
            ),
            icon: Icon(
              record.isActive != true
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
              color: AppColors.inactive,
            ),
          ),
        ],
        if (collection == AdminCollection.sosAlerts &&
            record.status != 'resolved' &&
            record.status != 'cancelled')
          IconButton(
            tooltip: 'Prendre en charge / résoudre',
            onPressed: () => useCases.updateSos(
              id: record.id,
              currentStatus: record.status,
              assignedOrganizationId: record.assignedOrganizationId,
              organizationId: organizationId,
            ),
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.primary,
            ),
          ),
        if (collection == AdminCollection.shelters &&
            (isAdmin || record.validationStatus == 'pending'))
          PopupMenuButton<String>(
            tooltip: isAdmin ? 'Changer le statut' : 'Examiner la proposition',
            initialValue: record.validationStatus ?? 'pending',
            onSelected: (status) =>
                useCases.setShelterValidationStatus(record.id, status, userId),
            itemBuilder: (context) => isAdmin
                ? const [
                    PopupMenuItem(value: 'validated', child: Text('Validé')),
                    PopupMenuItem(value: 'pending', child: Text('En attente')),
                    PopupMenuItem(value: 'rejected', child: Text('Rejeté')),
                  ]
                : const [
                    PopupMenuItem(value: 'validated', child: Text('Valider')),
                    PopupMenuItem(value: 'rejected', child: Text('Rejeter')),
                  ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.edit_outlined, color: AppColors.primary),
            ),
          ),
        if (collection == AdminCollection.zones &&
            (isAdmin || record.createdBy == userId))
          IconButton(
            tooltip: _zoneToggleLabel(record),
            onPressed: () => _confirmZoneToggle(context),
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
            tooltip: record.roles.contains('organizationMember')
                ? 'Modifier l’association organisation'
                : 'Associer à une organisation',
            onPressed: () => onManageOrganizationMembership(record),
            icon: const Icon(Icons.business_outlined, color: AppColors.primary),
          ),
        if (collection == AdminCollection.reports)
          IconButton(
            tooltip: 'Voir le signalement',
            onPressed: () => onViewReport(record),
            icon: const Icon(
              Icons.visibility_outlined,
              color: AppColors.primary,
            ),
          ),
        if (collection == AdminCollection.reports &&
            record.status != 'resolved')
          PopupMenuButton<String>(
            tooltip: 'Mettre à jour le signalement',
            itemBuilder: (context) => [
              if (record.status == 'open')
                const PopupMenuItem(
                  value: 'reviewed',
                  child: Text('Marquer comme examiné'),
                ),
              const PopupMenuItem(
                value: 'resolved',
                child: Text('Marquer comme résolu'),
              ),
            ],
            onSelected: (status) => useCases.updateReport(
              id: record.id,
              status: status,
              uid: userId,
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_vert, color: AppColors.primary),
            ),
          ),
        if (isAdmin &&
            collection == AdminCollection.users &&
            record.roles.contains('organizationMember'))
          IconButton(
            tooltip: 'Retirer le rôle organisation',
            onPressed: () => useCases.removeUserOrganizationRole(record.id),
            icon: const Icon(
              Icons.person_remove_alt_1,
              color: AppColors.inactive,
            ),
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

  String _zoneToggleLabel(AdminPortalRecord zone) {
    if (zone.zoneType == 'risk' && zone.zoneOrigin == 'manual') {
      return zone.isActive == true ? 'Clôturer l’alerte' : 'Réactiver l’alerte';
    }
    return zone.isActive == true ? 'Désactiver la zone' : 'Réactiver la zone';
  }

  Future<void> _confirmZoneToggle(BuildContext context) async {
    final closing = record.isActive == true;
    final isManualRiskAlert =
        record.zoneType == 'risk' && record.zoneOrigin == 'manual';
    final title = isManualRiskAlert
        ? closing
              ? 'Clôturer cette alerte ?'
              : 'Réactiver cette alerte ?'
        : closing
        ? 'Désactiver cette zone ?'
        : 'Réactiver cette zone ?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          isManualRiskAlert
              ? closing
                    ? 'L’alerte sera retirée de la carte et de l’écran Alertes des citoyens.'
                    : 'L’alerte réapparaîtra sur la carte et dans l’écran Alertes.'
              : closing
              ? 'Cette zone ne sera plus affichée aux citoyens.'
              : 'Cette zone sera de nouveau affichée aux citoyens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(closing ? 'Confirmer' : 'Réactiver'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await useCases.toggleZone(record.id, isActive: !closing);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de modifier cette zone.')),
        );
      }
    }
  }
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

String _zoneDetail(AdminPortalRecord record) {
  final type = switch (record.zoneType) {
    'safe' => 'Zone sûre',
    'risk' => 'Zone à risque',
    _ => 'Zone',
  };
  final origin = switch (record.zoneOrigin) {
    'automatic' => 'automatique',
    'manual' => 'manuelle',
    _ => 'origine inconnue',
  };
  final hazard = record.zoneType == 'risk'
      ? ' · ${_disasterLabel(record.disasterType)} · ${_severityLabel(record.severity)}'
      : '';
  return '$type $origin$hazard · ${record.geometry.length} points';
}

String _distressLabel(String? value) => switch (value) {
  'medical' => 'Urgence médicale',
  'security' => 'Sécurité',
  'accident' => 'Accident',
  'fire' => 'Incendie',
  'other' => 'Autre urgence',
  _ => 'Urgence',
};

String _shelterStatusLabel(String? value) => switch (value) {
  'open' => 'Ouvert',
  'almostFull' => 'Presque complet',
  'full' => 'Complet',
  'closed' => 'Fermé',
  _ => 'Disponibilité inconnue',
};

String _safetyStatusLabel(String? value) => switch (value) {
  'safe' => 'En sécurité',
  'inDistress' => 'En détresse',
  'unknown' => 'Situation inconnue',
  _ => 'Situation non renseignée',
};

String _rolesLabel(List<String> roles) => roles.isEmpty
    ? 'Aucun rôle'
    : roles
          .map(
            (role) => switch (role) {
              'admin' => 'Administrateur',
              'citizen' => 'Citoyen',
              'organizationMember' => 'Secouriste',
              _ => role,
            },
          )
          .join(', ');

String _shortCode(String value) =>
    value.length <= 8 ? value : value.substring(0, 8);

String _severityLabel(String? value) => switch (value) {
  'low' => 'Faible',
  'medium' => 'Modérée',
  'high' => 'Élevée',
  'critical' => 'Critique',
  _ => 'Gravité inconnue',
};

String _organizationType(String? type) => switch (type) {
  'ngo' => 'ONG',
  'government' => 'Administration',
  'emergencyServices' => 'Services d’urgence',
  'other' => 'Autre',
  _ => type ?? 'Organisation',
};

String _reportReason(String? reason) => switch (reason) {
  'unsafe' => 'Dangereux',
  'unavailable' => 'Indisponible',
  'blocked' => 'Bloqué',
  'other' => 'Autre motif',
  _ => 'Motif inconnu',
};

String _reportTarget(String? targetType) => switch (targetType) {
  'shelter' => 'Refuge',
  'zone' => 'Zone',
  'road' => 'Route',
  'other' => 'Autre élément',
  _ => 'Cible inconnue',
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
    'closed': 'Clôturée',
    'suspended': 'Suspendue',
    'unknown': 'Inconnu',
  };

  @override
  Widget build(BuildContext context) {
    final active = [
      'waiting',
      'pending',
      'open',
      'inProgress',
      'active',
      'verified',
      'validated',
    ].contains(value);
    final rejected = [
      'inactive',
      'suspended',
      'rejected',
      'cancelled',
    ].contains(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? AppColors.secondary.withValues(alpha: .16)
            : rejected
            ? Theme.of(context).colorScheme.error.withValues(alpha: .12)
            : AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labels[value] ?? value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: rejected
              ? Theme.of(context).colorScheme.error
              : AppColors.primary,
        ),
      ),
    );
  }
}
