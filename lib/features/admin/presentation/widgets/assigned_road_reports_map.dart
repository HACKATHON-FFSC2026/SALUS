import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';

class AssignedRoadReportsMap extends StatelessWidget {
  const AssignedRoadReportsMap({
    super.key,
    required this.reports,
    required this.onTapReport,
    this.tileProvider,
  });

  final List<AdminPortalRecord> reports;
  final ValueChanged<AdminPortalRecord> onTapReport;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    final roadReports = reports
        .where(
          (report) =>
              report.targetType == 'road' &&
              report.targetLocationLatitude != null &&
              report.targetLocationLongitude != null,
        )
        .toList(growable: false);
    if (roadReports.isEmpty) return const SizedBox.shrink();

    final first = roadReports.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incidents routiers affectés · ${roadReports.length}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    first.targetLocationLatitude!,
                    first.targetLocationLongitude!,
                  ),
                  initialZoom: 12,
                  initialCameraFit: roadReports.length > 1
                      ? CameraFit.coordinates(
                          coordinates: [
                            for (final report in roadReports)
                              LatLng(
                                report.targetLocationLatitude!,
                                report.targetLocationLongitude!,
                              ),
                          ],
                          padding: const EdgeInsets.all(36),
                          maxZoom: 15,
                        )
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.salus.app',
                    tileProvider: tileProvider,
                  ),
                  MarkerLayer(
                    markers: [
                      for (final report in roadReports)
                        Marker(
                          key: ValueKey('assigned-road-report-${report.id}'),
                          point: LatLng(
                            report.targetLocationLatitude!,
                            report.targetLocationLongitude!,
                          ),
                          width: 44,
                          height: 44,
                          child: Semantics(
                            button: true,
                            label: 'Ouvrir le signalement routier',
                            child: GestureDetector(
                              onTap: () => onTapReport(report),
                              child: const Icon(
                                Icons.report_problem,
                                color: AppColors.sos,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Touchez un repère pour consulter le signalement.',
            style: TextStyle(color: AppColors.inactive, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
