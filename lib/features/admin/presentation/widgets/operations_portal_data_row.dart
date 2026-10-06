import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/admin_portal_use_cases.dart';
import 'package:salus/features/admin/presentation/widgets/sos_assignment_dialog.dart';
import 'package:salus/features/admin/presentation/widgets/portal_action.dart';
import 'package:salus/features/admin/presentation/widgets/shelter_operations_dialog.dart';
import 'package:salus/features/admin/domain/models/shelter_operational_status.dart';

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
      '${_distressLabel(record.distressType)} · ${record.assignedOrganizationId == null ? 'Non assigné' : 'Organisation ${_shortCode(record.assignedOrganizationId!)}'} · ${record.responderCount} aidant${record.responderCount == 1 ? '' : 's'} · ${record.description ?? 'Aucun détail'} · ${_displayDate(record.createdAt)}',
    AdminCollection.users =>
      '${record.email ?? 'Email non renseigné'} · ${_rolesLabel(record.roles)} · ${_safetyStatusLabel(record.safetyStatus)}',
    AdminCollection.shelters =>
      '${record.address ?? 'Adresse non renseignée'} · ${_shelterStatusLabel(record.status)} · ${record.organizationId == null ? 'Non assigné' : 'Organisation ${_shortCode(record.organizationId!)}'} · ${record.capacityOccupied ?? 0}/${record.capacityTotal ?? 0} places',
    AdminCollection.organizations =>
      '${record.contactEmail ?? 'Email non renseigné'} · ${record.contactPhone ?? 'Téléphone non renseigné'} · ${_organizationType(record.type)}',
    AdminCollection.reports =>
      '${_reportReason(record.reason)} · ${_reportTarget(record.targetType)} · ${_shortCode(record.targetId ?? '')} · ${record.assignedOrganizationId == null ? 'Non assigné' : 'Organisation ${_shortCode(record.assignedOrganizationId!)}'} · ${_displayDate(record.createdAt)}',
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.inactive),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PortalStatusPill(_status, collection),
        if (collection == AdminCollection.sosAlerts)
          IconButton(
            tooltip: 'Détails du SOS et itinéraire',
            onPressed: () => _showSosDetails(context),
            icon: const Icon(Icons.info_outline, color: AppColors.primary),
          ),
        if (isAdmin &&
            collection == AdminCollection.organizations &&
            !record.verified)
          IconButton(
            tooltip: 'Vérifier',
            onPressed: () => runPortalAction(
              context,
              action: () => useCases.verifyOrganization(record.id, userId),
              successMessage: 'Organisation vérifiée.',
              confirmTitle: 'Vérifier cette organisation ?',
              confirmMessage:
                  'Elle pourra accueillir un compte membre et apparaître dans '
                  'l’annuaire public.',
              confirmLabel: 'Vérifier',
              confirmIcon: Icons.verified_outlined,
            ),
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
            onPressed: () => runPortalAction(
              context,
              action: () => useCases.setOrganizationActive(
                record.id,
                isActive: record.isActive != true,
              ),
              successMessage: record.isActive != true
                  ? 'Organisation réactivée.'
                  : 'Organisation suspendue.',
              confirmTitle: record.isActive != true
                  ? 'Réactiver cette organisation ?'
                  : 'Suspendre cette organisation ?',
              confirmMessage: record.isActive != true
                  ? 'Elle redeviendra visible et ses membres pourront accéder au portail.'
                  : 'Ses membres perdront l’accès au portail jusqu’à sa réactivation.',
              confirmLabel: record.isActive != true ? 'Réactiver' : 'Suspendre',
              destructive: record.isActive != true ? false : true,
            ),
            icon: Icon(
              record.isActive != true
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
              color: AppColors.inactive,
            ),
          ),
        ],
        if (isAdmin && _canAssignToOrganization)
          IconButton(
            tooltip: _assignedOrganizationId == null
                ? 'Assigner à une organisation'
                : 'Réassigner à une organisation',
            onPressed: () => _assignToOrganization(context),
            icon: const Icon(
              Icons.assignment_ind_outlined,
              color: AppColors.primary,
            ),
          ),
        if (collection == AdminCollection.sosAlerts &&
            isAdmin &&
            record.status == 'inProgress')
          IconButton(
            tooltip: 'Marquer le SOS comme résolu',
            onPressed: () => runPortalAction(
              context,
              action: () => useCases.updateSos(
                id: record.id,
                currentStatus: record.status,
                assignedOrganizationId: record.assignedOrganizationId,
                organizationId: organizationId,
              ),
              successMessage: 'SOS marqué comme résolu.',
              confirmTitle: 'Marquer ce SOS comme résolu ?',
              confirmMessage: 'La victime verra l’alerte comme résolue.',
              confirmLabel: 'Résoudre',
              destructive: true,
            ),
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          ),
        if (collection == AdminCollection.sosAlerts &&
            !isAdmin &&
            (record.status == 'assigned' || record.status == 'inProgress'))
          IconButton(
            tooltip: record.status == 'assigned'
                ? 'Confirmer la prise en charge'
                : 'Marquer comme résolu',
            onPressed: () => runPortalAction(
              context,
              action: () => useCases.updateSos(
                id: record.id,
                currentStatus: record.status,
                assignedOrganizationId: record.assignedOrganizationId,
                organizationId: organizationId,
              ),
              successMessage: record.status == 'inProgress'
                  ? 'SOS marqué comme résolu.'
                  : 'Prise en charge enregistrée.',
              confirmTitle: record.status == 'inProgress'
                  ? 'Marquer ce SOS comme résolu ?'
                  : 'Prendre en charge ce SOS ?',
              confirmMessage: record.status == 'inProgress'
                  ? 'La victime verra l’alerte comme résolue.'
                  : 'Votre organisation sera affichée comme intervenante.',
              confirmLabel: record.status == 'inProgress'
                  ? 'Résoudre'
                  : 'Prendre en charge',
              destructive: record.status == 'inProgress',
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
            onSelected: (status) => runPortalAction(
              context,
              action: () => useCases.setShelterValidationStatus(
                record.id,
                status,
                userId,
              ),
              successMessage: switch (status) {
                'validated' => 'Refuge validé.',
                'rejected' => 'Refuge rejeté.',
                _ => 'Statut du refuge mis à jour.',
              },
              confirmTitle: status == 'rejected'
                  ? 'Rejeter cette proposition de refuge ?'
                  : null,
              confirmMessage: status == 'rejected'
                  ? 'Elle ne sera pas affichée aux citoyens sur la carte.'
                  : null,
              confirmLabel: 'Rejeter',
              destructive: status == 'rejected',
            ),
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
        if (collection == AdminCollection.shelters &&
            (isAdmin ||
                (organizationId != null &&
                    record.validationStatus == 'validated')))
          IconButton(
            tooltip: 'Mettre à jour la disponibilité',
            onPressed: () => _editShelterOperations(context),
            icon: const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.primary,
            ),
          ),
        if (collection == AdminCollection.zones &&
            (isAdmin || record.organizationId == organizationId))
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
            (isAdmin || record.organizationId == organizationId))
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
            onSelected: (status) => runPortalAction(
              context,
              action: () => useCases.updateReport(
                id: record.id,
                status: status,
                uid: userId,
              ),
              successMessage: status == 'resolved'
                  ? 'Signalement marqué comme résolu.'
                  : 'Signalement marqué comme examiné.',
              confirmTitle: status == 'resolved'
                  ? 'Marquer ce signalement comme résolu ?'
                  : null,
              confirmLabel: 'Résoudre',
              destructive: status == 'resolved',
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
            onPressed: () => runPortalAction(
              context,
              action: () => useCases.removeUserOrganizationRole(record.id),
              successMessage: 'Rôle organisation retiré.',
              confirmTitle: 'Retirer l’accès organisation ?',
              confirmMessage:
                  'Ce compte n’aura plus accès au portail de son organisation.',
              confirmLabel: 'Retirer',
              destructive: true,
            ),
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
            onPressed: () => runPortalAction(
              context,
              action: () => useCases.setUserActive(
                record.id,
                isActive: record.isActive == false,
              ),
              successMessage: record.isActive == false
                  ? 'Compte réactivé.'
                  : 'Compte désactivé.',
              confirmTitle: record.isActive == false
                  ? 'Réactiver ce compte ?'
                  : 'Désactiver ce compte ?',
              confirmMessage: record.isActive == false
                  ? 'Le compte pourra de nouveau se connecter.'
                  : 'Ce compte ne pourra plus se connecter.',
              confirmLabel: record.isActive == false
                  ? 'Réactiver'
                  : 'Désactiver',
              destructive: record.isActive != false,
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

  Future<void> _assignToOrganization(BuildContext context) async {
    final assigned = await showDialog<bool>(
      context: context,
      builder: (_) => OrganizationAssignmentDialog(
        title: switch (collection) {
          AdminCollection.sosAlerts => 'Affecter le SOS',
          AdminCollection.reports => 'Affecter le signalement',
          AdminCollection.shelters => 'Affecter la proposition de refuge',
          _ => 'Affecter à une organisation',
        },
        description: record.description ?? record.title,
        currentOrganizationId: _assignedOrganizationId,
        confirmLabel: 'Affecter',
        useCases: useCases,
        onAssign: (organizationId) => switch (collection) {
          AdminCollection.sosAlerts => useCases.assignSosToOrganization(
            record.id,
            organizationId,
          ),
          AdminCollection.reports => useCases.assignReportToOrganization(
            record.id,
            organizationId,
          ),
          AdminCollection.shelters => useCases.assignShelterToOrganization(
            record.id,
            organizationId,
          ),
          _ => Future<void>.value(),
        },
      ),
    );
    if (assigned == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Affectation enregistrée.')));
    }
  }

  Future<void> _editShelterOperations(BuildContext context) async {
    final status = ShelterOperationalStatus.values.firstWhere(
      (value) => value.name == record.status,
      orElse: () => ShelterOperationalStatus.open,
    );
    await showDialog<void>(
      context: context,
      builder: (_) => ShelterOperationsDialog(
        capacityTotal: record.capacityTotal ?? 0,
        capacityOccupied: record.capacityOccupied ?? 0,
        status: status,
        onSave: (nextStatus, capacityOccupied) =>
            useCases.updateShelterOperations(
              id: record.id,
              status: nextStatus,
              capacityOccupied: capacityOccupied,
            ),
      ),
    );
  }

  Future<void> _showSosDetails(BuildContext context) async {
    final latitude = record.locationLatitude;
    final longitude = record.locationLongitude;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('SOS · ${_distressLabel(record.distressType)}'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SosDetailLine('Statut', _statusLabel(record.status)),
                _SosDetailLine(
                  'Référence de la personne',
                  _shortCode(record.userId ?? record.id),
                ),
                _SosDetailLine('Créé le', _displayDate(record.createdAt)),
                _SosDetailLine('Aidants inscrits', '${record.responderCount}'),
                const SizedBox(height: 14),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  record.description?.trim().isNotEmpty == true
                      ? record.description!.trim()
                      : 'Aucun détail ajouté par la personne.',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dernière position connue',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                if (latitude != null && longitude != null) ...[
                  SizedBox(
                    height: 260,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(latitude, longitude),
                          initialZoom: 15,
                          minZoom: 4,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.salus.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(latitude, longitude),
                                width: 44,
                                height: 52,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: AppColors.sos,
                                  size: 44,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                  ),
                  Text(
                    record.locationUpdatedAt == null
                        ? 'Position initiale'
                        : 'Mise à jour : ${_displayDate(record.locationUpdatedAt)}',
                    style: const TextStyle(
                      color: AppColors.inactive,
                      fontSize: 12,
                    ),
                  ),
                ] else
                  const Text('Position indisponible.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: latitude == null || longitude == null
                ? null
                : () => _openSosRoute(context, latitude, longitude),
            icon: const Icon(Icons.directions),
            label: const Text('Itinéraire'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSosRoute(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir l’itinéraire.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir l’itinéraire.')),
        );
      }
    }
  }

  String? get _assignedOrganizationId => collection == AdminCollection.shelters
      ? record.organizationId
      : record.assignedOrganizationId;

  bool get _canAssignToOrganization => switch (collection) {
    AdminCollection.sosAlerts =>
      record.status != 'resolved' && record.status != 'cancelled',
    AdminCollection.reports => record.status != 'resolved',
    AdminCollection.shelters => record.validationStatus != 'rejected',
    _ => false,
  };

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

class _SosDetailLine extends StatelessWidget {
  const _SosDetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: const TextStyle(color: AppColors.inactive)),
        ),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ],
    ),
  );
}

String _statusLabel(String? status) => switch (status) {
  'waiting' => 'En attente d’affectation',
  'assigned' => 'Affecté à une organisation',
  'inProgress' => 'Intervention en cours',
  'resolved' => 'Résolu',
  'cancelled' => 'Annulé',
  _ => status ?? 'Inconnu',
};

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
  const _PortalStatusPill(this.value, this.collection);

  final String value;
  final AdminCollection collection;

  static const _labels = {
    'waiting': 'En attente',
    'assigned': 'Assignée',
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

  /// `resolved` s'accorde avec l'objet : une alerte (SOS) est « résolue », un
  /// signalement est « résolu ». La pastille est partagée entre collections.
  String get _pillLabel {
    if (value == 'resolved' && collection == AdminCollection.reports) {
      return 'Résolu';
    }
    return _labels[value] ?? value;
  }

  @override
  Widget build(BuildContext context) {
    final active = [
      'waiting',
      'assigned',
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
        _pillLabel,
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
