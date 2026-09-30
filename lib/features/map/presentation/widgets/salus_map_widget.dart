import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';
import 'package:salus/features/map/presentation/utils/map_animation_helper.dart';
import 'package:toastification/toastification.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_bottom_sheet.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_marker_pin.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';

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
  bool _showLegend = false;

  @override
  void initState() {
    super.initState();
    // Demander la permission et récupérer la position au démarrage. Le
    // microtask peut s'exécuter après un unmount: `ref.read` lèverait.
    Future.microtask(() {
      if (!mounted) return;
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
    final sheltersAsync = ref.watch(validatedSheltersProvider);
    final shelters = sheltersAsync.value ?? const <Shelter>[];

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
                alignPositionOnUpdate:
                    AlignOnUpdate.never, // Pas de centrage forcé auto
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  markerSize: Size(35, 35),
                  accuracyCircleColor: Color(0x3314213D),
                  headingSectorColor: Color(0x44FCA311),
                ),
              ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 48,
                size: const Size(42, 42),
                maxZoom: 15,
                markers: [
                  for (final shelter in shelters)
                    Marker(
                      key: ValueKey('shelter-marker-${shelter.id}'),
                      point: LatLng(
                        shelter.location.latitude,
                        shelter.location.longitude,
                      ),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showShelterBottomSheet(context, shelter),
                        child: ShelterMarkerPin(status: shelter.status),
                      ),
                    ),
                ],
                builder: (context, markers) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondary, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 5),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${markers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (sheltersAsync.hasError ||
            sheltersAsync.isLoading ||
            shelters.isEmpty)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: _shelterBanner(sheltersAsync),
          ),

        Positioned(
          left: 16,
          bottom: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showLegend) const _ShelterLegend(),
              const SizedBox(width: 6),
              FloatingActionButton.small(
                heroTag: 'shelter_legend_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                tooltip: _showLegend
                    ? 'Masquer la légende'
                    : 'Légende des refuges',
                onPressed: () => setState(() => _showLegend = !_showLegend),
                child: Icon(_showLegend ? Icons.close : Icons.info_outline),
              ),
            ],
          ),
        ),

        // Contrôle secondaire de carte, sous le bandeau de situation.
        Positioned(
          top: MediaQuery.paddingOf(context).top + 76,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'recenter_gps_fab',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: () => _onRecenterPressed(locationState),
            child: locationState.status == LocationStatus.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Widget _shelterBanner(AsyncValue<List<Shelter>> value) {
    final message = value.hasError
        ? 'Impossible de charger les refuges.'
        : value.isLoading && !value.hasValue
        ? 'Chargement des refuges…'
        : 'Aucun refuge disponible à proximité.';
    return Card(
      color: AppColors.surface.withValues(alpha: 0.9),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.home_work_outlined),
        title: Text(message),
        trailing: value.hasError
            ? TextButton(
                onPressed: () => ref.invalidate(validatedSheltersProvider),
                child: const Text('Réessayer'),
              )
            : null,
      ),
    );
  }
}

class _ShelterLegend extends StatelessWidget {
  const _ShelterLegend();

  @override
  Widget build(BuildContext context) {
    const statuses = [
      ShelterStatus.open,
      ShelterStatus.almostFull,
      ShelterStatus.full,
      ShelterStatus.closed,
    ];
    return Card(
      color: AppColors.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final status in statuses)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(status.icon, size: 13, color: status.foregroundColor),
                  const SizedBox(width: 4),
                  Text(status.label, style: const TextStyle(fontSize: 11)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
