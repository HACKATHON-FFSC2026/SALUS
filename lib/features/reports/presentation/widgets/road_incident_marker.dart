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
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.report_problem_outlined,
          color: Colors.white,
          size: 22,
        ),
      ),
    ),
  );

  Future<void> _showDetails(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.sos.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.report_problem_outlined,
                      color: AppColors.sos,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Incident routier',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _InfoRow(
                icon: Icons.warning_amber_rounded,
                text: 'Motif : ${_reasonLabel(incident.reason)}',
              ),
              if (incident.description?.trim().isNotEmpty == true)
                _InfoRow(
                  icon: Icons.notes_outlined,
                  text: incident.description!.trim(),
                ),
              _InfoRow(
                icon: Icons.schedule,
                text: 'Signalé le ${_formatDate(incident.createdAt)}',
              ),
              _InfoRow(
                icon: Icons.info_outline,
                text:
                    'Statut : ${incident.status == 'reviewed' ? 'Examiné' : 'À traiter'}',
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
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

/// Ligne « icône + texte » du détail d'un incident.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.inactive),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
