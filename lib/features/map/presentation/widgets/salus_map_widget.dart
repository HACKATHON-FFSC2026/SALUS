import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';
import 'package:salus/features/map/presentation/utils/map_animation_helper.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/risks/presentation/widgets/disaster_marker_pin.dart';
import 'package:toastification/toastification.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_bottom_sheet.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_marker_pin.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';
import 'package:salus/features/risks/presentation/mappers/zone_ui_mapper.dart';

class SalusMapWidget extends ConsumerStatefulWidget {
  const SalusMapWidget({super.key, this.tileProvider});

  /// Seam de test: les tuiles OSM demandent le réseau, ce qui laisse des
  /// timers en vol et fait échouer le moindre test de widget. Les tests
  /// injectent `ErrorTileProvider`; en production on garde le réseau.
  final TileProvider? tileProvider;

  @override
  ConsumerState<SalusMapWidget> createState() => _SalusMapWidgetState();
}

class _SalusMapWidgetState extends ConsumerState<SalusMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  // ponytail: une seule animation à la fois, l'ancienne est annulée.
  // Sans ça, double-tap = 2 tickers sur SingleTickerProvider = crash.
  AnimationController? _anim;

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

  @override
  void dispose() {
    _anim?.stop();
    _anim?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Action du clic sur le FAB : Recentrer la carte avec animation
  void _onRecenterPressed(GeoPoint? position) {
    if (position != null) {
      // 1. Position disponible -> Animation vers les coordonnées GPS.
      // L'animation précédente est annulée avant d'en lancer une autre.
      _anim?.stop();
      _anim?.dispose();
      final controller = _mapController.animatedMove(
        vsync: this,
        destLocation: LatLng(position.latitude, position.longitude),
        destZoom: 16.0,
        duration: const Duration(milliseconds: 1000),
      );
      _anim = controller;
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          controller.dispose();
          if (_anim == controller) _anim = null;
        }
      });
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
    // ponytail: selects ciblés, un changement de statut seul (loading →
    // error, même position) ne reconstruit pas les polygones/markers.
    final locationPosition = ref.watch(
      locationProvider.select((s) => s.position),
    );
    final locationStatus = ref.watch(locationProvider.select((s) => s.status));
    final sheltersAsync = ref.watch(validatedSheltersProvider);
    final shelters = sheltersAsync.value ?? const <Shelter>[];
    final externalRiskZones =
        ref.watch(riskZonesProvider).value ?? const <Zone>[];
    final streamedRiskZones =
        ref.watch(activeRiskZonesProvider).value ?? const <Zone>[];
    final riskZonesById = <String, Zone>{
      for (final zone in externalRiskZones)
        if (zone.isActive && zone.geometry.isNotEmpty) zone.id: zone,
      // Firestore zones take precedence when both sources use the same ID.
      for (final zone in streamedRiskZones)
        if (zone.isActive && zone.geometry.isNotEmpty) zone.id: zone,
    };
    final riskZones = riskZonesById.values.toList();
    final safeZones =
        (ref.watch(filteredSafeZonesProvider).value ?? const <Zone>[])
            .where((z) => z.geometry.isNotEmpty)
            .toList();
    final position = locationPosition;
    final geofence = ref.watch(geofenceServiceProvider);
    final userDanger = position == null
        ? const <Zone>[]
        : riskZones.where((zone) {
            return zone.type == ZoneType.risk &&
                geofence.isUserInZone(
                  firestore.GeoPoint(position.latitude, position.longitude),
                  zone,
                );
          }).toList();

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
              tileProvider: widget.tileProvider,
            ),
            if (safeZones.isNotEmpty || riskZones.isNotEmpty)
              PolygonLayer(
                polygons: [
                  for (final zone in safeZones) zone.toPolygon(),
                  for (final zone in riskZones) zone.toPolygon(),
                ],
              ),

            MarkerLayer(
              markers: [
                for (final z in riskZones)
                  Marker(
                    key: ValueKey('risk-marker-${z.id}'),
                    point: z.center,
                    width: 40,
                    height: 40,
                    child: DisasterMarkerPin(zone: z),
                  ),
              ],
            ),

            // ponytail: CurrentLocationLayer ouvre son propre flux geolocator.
            // Le recentrage passe par notre port, la pastille par le plugin.
            // Brancher les deux sur LocationRepository quand un suivi continu
            // est requis (widget dissocié de sa pastille).
            // ponytail: la pastille suit la dernière position connue, même
            // après une erreur transitoire (le status repasse en loading
            // au retry, la position est conservée par le provider).
            if (locationPosition != null)
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
              if (_showLegend) const _MapLegend(),
              const SizedBox(width: 6),
              // Vue AR des refuges et des zones proches.
              FloatingActionButton.small(
                heroTag: 'ar_view_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                tooltip: 'Vue caméra des refuges et zones proches',
                onPressed: () => context.router.push(const ArViewRoute()),
                child: const Icon(Icons.view_in_ar_outlined),
              ),
              const SizedBox(width: 6),
              FloatingActionButton.small(
                heroTag: 'shelter_legend_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                tooltip: _showLegend
                    ? 'Masquer la légende'
                    : 'Légende de la carte',
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
            onPressed: () => _onRecenterPressed(locationPosition),
            child: locationStatus == LocationStatus.loading
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

        // Alerte compacte sous le bandeau principal, près du haut de l'écran.
        // On laisse une marge à droite pour le bouton de recentrage.
        if (userDanger.isNotEmpty)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 76,
            left: 16,
            right: 72,
            child: Material(
              color: Colors.red.shade50.withValues(alpha: 0.96),
              elevation: 3,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zone à risque · ${userDanger.first.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff8f2020),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

Color _zoneColor(Severity? severity) => switch (severity) {
  Severity.low => const Color(0xffe9a23b),
  Severity.medium => const Color(0xffe47736),
  Severity.high => const Color(0xffc94b4b),
  Severity.critical => const Color(0xff8f2020),
  null => const Color(0xffc94b4b),
};

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    const statuses = [
      ShelterStatus.open,
      ShelterStatus.almostFull,
      ShelterStatus.full,
      ShelterStatus.closed,
    ];
    const severities = {
      Severity.low: 'Risque faible',
      Severity.medium: 'Risque modéré',
      Severity.high: 'Risque élevé',
      Severity.critical: 'Risque critique',
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 90,
      ),
      child: Card(
        color: AppColors.surface.withValues(alpha: 0.92),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final entry in severities.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: _zoneColor(entry.key),
                    ),
                    const SizedBox(width: 4),
                    Text(entry.value, style: const TextStyle(fontSize: 11)),
                  ],
                ),
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
      ),
    );
  }
}
