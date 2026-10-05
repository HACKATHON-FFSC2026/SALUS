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
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choisir le lieu de l’incident',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
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
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'Touchez la carte pour placer le repère à l’endroit concerné.',
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _initialLocation,
                  initialZoom: 16,
                  onTap: (_, point) => setState(() {
                    _selectedLocation = point;
                  }),
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
                      if (_selectedLocation case final selected?)
                        Marker(
                          point: selected,
                          width: 46,
                          height: 46,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.gpsUnavailable)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'GPS indisponible. La carte est centrée sur Antananarivo ; choisissez le point exact manuellement.',
                          style: TextStyle(color: AppColors.sos, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Text(
                      _selectedLocation == null
                          ? 'Aucun point sélectionné'
                          : 'Point sélectionné',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _selectedLocation == null
                          ? null
                          : () => Navigator.of(context).pop(
                              GeoPoint(
                                latitude: _selectedLocation!.latitude,
                                longitude: _selectedLocation!.longitude,
                              ),
                            ),
                      icon: const Icon(Icons.check),
                      label: const Text('Utiliser ce point'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
