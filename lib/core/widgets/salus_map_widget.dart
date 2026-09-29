import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/utils/map_animation_helper.dart';
import 'package:toastification/toastification.dart';
import 'package:salus/features/map/presentation/controllers/location_controller.dart';
import 'package:salus/features/map/domain/models/location_state.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_bottom_sheet.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_marker_pin.dart';

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
      ref.read(locationControllerProvider.notifier).checkAndRequestPermission();
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
      ref.read(locationControllerProvider.notifier).checkAndRequestPermission();

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
    final locationState = ref.watch(locationControllerProvider);
    final sheltersAsync = ref.watch(validatedSheltersProvider);
    // Un seul flux pour tous les markers : aucune requête Firestore par refuge.
    final shelters = sheltersAsync.value ?? const <Shelter>[];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Carte OpenStreetMap
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

              // 2. Refuges validés, positionnés sur Shelter.location.
              MarkerLayer(
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
              ),
            ],
          ),

          // 3. État du chargement des refuges (la carte reste utilisable).
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: _buildShelterBanner(sheltersAsync),
          ),

          // 4. Bouton Flottant (FAB) de recentrage
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
      ),
    );
  }

  /// Bandeau discret sur l'état des refuges : chargement, erreur Firestore ou
  /// absence de refuge validé. La carte reste utilisable dans tous les cas.
  Widget _buildShelterBanner(AsyncValue<List<Shelter>> sheltersAsync) {
    if (sheltersAsync.hasError) {
      return _MapBanner(
        icon: Icons.cloud_off,
        message: 'Impossible de charger les refuges.',
        actionLabel: 'Réessayer',
        onAction: () => ref.invalidate(validatedSheltersProvider),
      );
    }

    if (sheltersAsync.isLoading && !sheltersAsync.hasValue) {
      return const _MapBanner(
        icon: Icons.home_work_outlined,
        message: 'Chargement des refuges…',
        showProgress: true,
      );
    }

    if ((sheltersAsync.value ?? const <Shelter>[]).isEmpty) {
      return const _MapBanner(
        icon: Icons.home_work_outlined,
        message: 'Aucun refuge disponible à proximité.',
      );
    }

    return const SizedBox.shrink();
  }
}

/// Bandeau aligné sur le style des overlays existants de la carte.
class _MapBanner extends StatelessWidget {
  const _MapBanner({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;

    return Card(
      color: AppColors.surface.withValues(alpha: 0.9),
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (showProgress)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}