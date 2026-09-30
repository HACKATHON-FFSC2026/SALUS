import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';
import 'package:salus/features/map/presentation/utils/map_animation_helper.dart';
import 'package:toastification/toastification.dart';

class SalusMapWidget extends ConsumerStatefulWidget {
  const SalusMapWidget({super.key});

  @override
  ConsumerState<SalusMapWidget> createState() => _SalusMapWidgetState();
}

class _SalusMapWidgetState extends ConsumerState<SalusMapWidget>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Position par défaut (Antananarivo) avant la première fixation GPS
  static const LatLng _defaultLocation = LatLng(-18.8792, 47.5079);

  @override
  void initState() {
    super.initState();
    // Demander la permission et récupérer la position au démarrage
    Future.microtask(() {
      ref.read(locationProvider.notifier).refresh();
    });
  }

  /// Action du clic sur le FAB : Recentrer la carte avec animation
  void _onRecenterPressed(LocationState locationState) {
    final position = locationState.position;

    if (position != null) {
      // 1. Position disponible -> Animation vers les coordonnées GPS
      _mapController.animatedMove(
        vsync: this,
        destLocation: LatLng(position.latitude, position.longitude),
        destZoom: 16.0,
        duration: const Duration(milliseconds: 1000),
      );
    } else {
      // 2. Position non encore chargée -> Demander / Relancer le GPS
      ref.read(locationProvider.notifier).refresh();

      toastification.show(
        context: context,
        title: const Text('Recherche du signal GPS...'),
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _defaultLocation,
            initialZoom: 13.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.salus.app',
            ),

            // ponytail: CurrentLocationLayer ouvre son propre flux geolocator.
            // Le recentrage passe par notre port, la pastille par le plugin.
            // Brancher les deux sur LocationRepository quand un suivi continu
            // est requis (widget dissocié de sa pastille).
            if (locationState.status == LocationStatus.success)
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.never, // Pas de centrage forcé auto
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  markerSize: Size(35, 35),
                  accuracyCircleColor: Color.fromARGB(51, 80, 137, 184),
                  headingSectorColor: Color(0x442196F3),
                ),
              ),
          ],
        ),

        // Bouton flottant de recentrage
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'recenter_gps_fab',
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => _onRecenterPressed(locationState),
            child: locationState.status == LocationStatus.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
