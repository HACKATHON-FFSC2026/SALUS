import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/reports/domain/models/road_incident.dart';

class RoadIncidentMarker extends StatelessWidget {
  const RoadIncidentMarker({super.key, required this.incident});

  final RoadIncident incident;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Incident routier signalé',
    child: GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sos,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.report_problem_outlined,
          color: Colors.white,
          size: 21,
        ),
      ),
    ),
  );

  Future<void> _showDetails(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Incident routier'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Motif : ${_reasonLabel(incident.reason)}'),
          if (incident.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(incident.description!.trim()),
          ],
          const SizedBox(height: 8),
          Text('Signalé le ${_formatDate(incident.createdAt)}'),
          const SizedBox(height: 8),
          Text(
            'Statut : ${incident.status == 'reviewed' ? 'Examiné' : 'À traiter'}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );

  static String _reasonLabel(String reason) => switch (reason) {
    'blocked' => 'Route bloquée',
    'unsafe' => 'Route dangereuse',
    'unavailable' => 'Route indisponible',
    _ => 'Autre',
  };

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} à $hour:$minute';
  }
}
