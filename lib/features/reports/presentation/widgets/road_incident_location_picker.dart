import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/map/domain/location.dart';

Future<GeoPoint?> showRoadIncidentLocationPicker(
  BuildContext context, {
  required GeoPoint initialLocation,
  bool gpsUnavailable = false,
  TileProvider? tileProvider,
}) {
  return showDialog<GeoPoint>(
    context: context,
    builder: (_) => _RoadIncidentLocationPicker(
      initialLocation: initialLocation,
      gpsUnavailable: gpsUnavailable,
      tileProvider: tileProvider,
    ),
  );
}

class _RoadIncidentLocationPicker extends StatefulWidget {
  const _RoadIncidentLocationPicker({
    required this.initialLocation,
    required this.gpsUnavailable,
    this.tileProvider,
  });

  final GeoPoint initialLocation;
  final bool gpsUnavailable;
  final TileProvider? tileProvider;

  @override
  State<_RoadIncidentLocationPicker> createState() =>
      _RoadIncidentLocationPickerState();
}

class _RoadIncidentLocationPickerState
    extends State<_RoadIncidentLocationPicker> {
  late final LatLng _initialLocation = LatLng(
    widget.initialLocation.latitude,
    widget.initialLocation.longitude,
  );
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final selected = _selectedLocation;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choisir le lieu de l’incident',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Annuler',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 18,
                    color: AppColors.inactive,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Touchez la carte pour placer le repère à l’endroit '
                      'concerné.',
                      style: TextStyle(color: AppColors.inactive, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.inactive.withValues(alpha: .2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _initialLocation,
                        initialZoom: 16,
                        onTap: (_, point) =>
                            setState(() => _selectedLocation = point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.salus.app',
                          tileProvider: widget.tileProvider,
                        ),
                        MarkerLayer(
                          markers: [
                            if (selected != null)
                              Marker(
                                point: selected,
                                width: 48,
                                height: 48,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: AppColors.sos,
                                  size: 46,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.gpsUnavailable)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _GpsWarning(),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected == null
                            ? Icons.location_off_outlined
                            : Icons.location_on,
                        size: 18,
                        color: selected == null
                            ? AppColors.inactive
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selected == null
                            ? 'Aucun point sélectionné'
                            : 'Point sélectionné',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected == null
                              ? AppColors.inactive
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: selected == null
                        ? null
                        : () => Navigator.of(context).pop(
                            GeoPoint(
                              latitude: selected.latitude,
                              longitude: selected.longitude,
                            ),
                          ),
                    icon: const Icon(Icons.check),
                    label: const Text('Utiliser ce point'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsWarning extends StatelessWidget {
  const _GpsWarning();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.sos.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.gps_off_outlined, size: 18, color: AppColors.sos),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'GPS indisponible. La carte est centrée sur Antananarivo ; '
            'choisissez le point exact manuellement.',
            style: TextStyle(color: AppColors.sos, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
