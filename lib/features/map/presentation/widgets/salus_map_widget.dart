import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';
import 'package:salus/features/map/presentation/utils/map_animation_helper.dart';
import 'package:salus/features/map/presentation/widgets/zone_bottom_sheet.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/risks/presentation/widgets/disaster_marker_pin.dart';
import 'package:toastification/toastification.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_bottom_sheet.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_marker_pin.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';
import 'package:salus/features/risks/presentation/mappers/zone_ui_mapper.dart';
import 'package:salus/features/sos/presentation/providers/active_sos_provider.dart';
import 'package:salus/features/reports/presentation/widgets/report_issue_action.dart';
import 'package:salus/features/reports/presentation/providers/report_providers.dart';
import 'package:salus/features/reports/presentation/widgets/road_incident_marker.dart';

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
  // Résultat du dernier hit-test sur les polygones de zones; lu par
  // FlutterMap.onTap pour ouvrir la fiche de la zone touchée.
  final LayerHitNotifier<Zone> _polygonHitNotifier = ValueNotifier(null);
  // ponytail: une seule animation à la fois, l'ancienne est annulée.
  // Sans ça, double-tap = 2 tickers sur SingleTickerProvider = crash.
  AnimationController? _anim;

  // Position par défaut (Antananarivo) avant la première fixation GPS
  static const LatLng _defaultLocation = LatLng(-18.8792, 47.5079);

  void _showMapLegend() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _MapLegend(),
        ),
      ),
    );
  }

  void _showMapActions(WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Signaler un incident routier'),
              onTap: () {
                Navigator.pop(sheetContext);
                launchRoadIncidentReport(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Comprendre la carte'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showMapLegend();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
    _polygonHitNotifier.dispose();
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
    final roadIncidentsAsync = ref.watch(myRoadIncidentsProvider);
    final roadIncidents = roadIncidentsAsync.value ?? const [];
    final sheltersAsync = ref.watch(validatedSheltersProvider);
    final shelters = sheltersAsync.value ?? const <Shelter>[];
    final activeSos =
        ref.watch(activeSosStreamProvider).value ?? const <SOSAlert>[];
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
    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultLocation,
            initialZoom: 13.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            // Clic dans un polygone de zone (sûre ou catastrophe) : le
            // hit-test du painter alimente _polygonHitNotifier avant le
            // callback (pattern du flutter_map example « polygons.dart »).
            onTap: (tapPosition, _) {
              final zone = _polygonHitNotifier.value?.hitValues.firstOrNull;
              if (zone != null) showZoneBottomSheet(context, zone);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.salus.app',
              tileProvider: widget.tileProvider,
            ),
            if (safeZones.isNotEmpty || riskZones.isNotEmpty)
              PolygonLayer<Zone>(
                hitNotifier: _polygonHitNotifier,
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showZoneBottomSheet(context, z),
                      child: DisasterMarkerPin(zone: z),
                    ),
                  ),
                for (final incident in roadIncidents)
                  Marker(
                    key: ValueKey('road-incident-${incident.id}'),
                    point: LatLng(incident.latitude, incident.longitude),
                    width: 42,
                    height: 42,
                    child: RoadIncidentMarker(incident: incident),
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

            // SOS actifs, ajoutés en dernier donc au-dessus des autres calques:
            // c'est l'objet le plus urgent de la carte et il en était absent.
            MarkerLayer(
              markers: [
                for (final sos in activeSos)
                  Marker(
                    key: ValueKey('sos-marker-${sos.id}'),
                    point: LatLng(
                      sos.location.latitude,
                      sos.location.longitude,
                    ),
                    width: 46,
                    height: 46,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          context.router.push(const ActiveSosListRoute()),
                      child: const _SosMarkerPin(),
                    ),
                  ),
              ],
            ),
          ],
        ),

        if (sheltersAsync.hasError ||
            sheltersAsync.isLoading ||
            shelters.isEmpty ||
            roadIncidentsAsync.hasError)
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: _mapStatusBanner(
              sheltersAsync,
              hasShelterNotice:
                  sheltersAsync.hasError ||
                  sheltersAsync.isLoading ||
                  shelters.isEmpty,
              hasRoadIncidentError: roadIncidentsAsync.hasError,
            ),
          ),

        Positioned(
          left: 16,
          bottom: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'ar_view_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                tooltip: 'Vue caméra des refuges et zones proches',
                onPressed: () => context.router.push(const ArViewRoute()),
                child: const Icon(Icons.view_in_ar_outlined),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'map_actions_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                tooltip: 'Autres actions de la carte',
                onPressed: () => _showMapActions(ref),
                child: const Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),

        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'recenter_gps_fab',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            tooltip: locationStatus == LocationStatus.loading
                ? 'Localisation en cours'
                : locationPosition == null
                ? 'Rechercher ma position'
                : 'Recentrer sur ma position',
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
      ],
    );
  }

  Widget _mapStatusBanner(
    AsyncValue<List<Shelter>> shelters, {
    required bool hasShelterNotice,
    required bool hasRoadIncidentError,
  }) => Card(
    color: AppColors.surface.withValues(alpha: 0.96),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasShelterNotice)
            Row(
              children: [
                const Icon(Icons.home_work_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shelters.hasError
                        ? 'Impossible de charger les refuges.'
                        : shelters.isLoading && !shelters.hasValue
                        ? 'Chargement des refuges…'
                        : 'Aucun refuge disponible à proximité.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (shelters.hasError)
                  TextButton(
                    onPressed: () => ref.invalidate(validatedSheltersProvider),
                    child: const Text('Réessayer'),
                  ),
              ],
            ),
          if (hasShelterNotice && hasRoadIncidentError)
            const Divider(height: 12),
          if (hasRoadIncidentError)
            const Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  size: 20,
                  color: AppColors.sos,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Impossible de charger vos signalements routiers.',
                    style: TextStyle(color: AppColors.sos, fontSize: 12),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

Color _zoneColor(Severity? severity) => switch (severity) {
  Severity.low => const Color(0xffe9a23b),
  Severity.medium => const Color(0xffe47736),
  Severity.high => const Color(0xffc94b4b),
  Severity.critical => const Color(0xff8f2020),
  null => const Color(0xffc94b4b),
};

class _SosMarkerPin extends StatelessWidget {
  const _SosMarkerPin();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.sos,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [
        BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
      ],
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.sos, color: Colors.white, size: 22),
  );
}

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
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sos, size: 13, color: AppColors.sos),
                  SizedBox(width: 4),
                  Text('SOS actif', style: TextStyle(fontSize: 11)),
                ],
              ),
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
