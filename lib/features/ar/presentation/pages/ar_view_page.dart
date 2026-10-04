import 'package:ar_location_view/ar_location_view.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/ar/presentation/models/salus_ar_annotation.dart';
import 'package:salus/features/ar/presentation/providers/ar_annotations_provider.dart';
import 'package:salus/features/ar/presentation/widgets/ar_annotation_card.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';

/// Vue caméra avec les refuges et zones autour de l'utilisateur (spec §1.1,
/// « Réalité augmentée », SHOULD). Position/cap/permissions gérés par
/// ar_location_view.
@RoutePage()
class ArViewPage extends ConsumerStatefulWidget {
  const ArViewPage({super.key});

  @override
  ConsumerState<ArViewPage> createState() => _ArViewPageState();
}

class _ArViewPageState extends ConsumerState<ArViewPage> {
  // ponytail: clé forcée pour « Réessayer » après refus de permission;
  // ArLocationWidget possèdera son flux capteurs et doit être recréé.
  int _sessionKey = 0;

  /// Filtres par type. Zones à risque masquées par défaut: sur le terrain,
  /// on cherche d'abord où aller, pas où ne pas aller (spec §1.1).
  bool _showShelters = true;
  bool _showSafeZones = true;
  bool _showRiskZones = false;

  @override
  Widget build(BuildContext context) {
    final annotations = ref
        .watch(arAnnotationsProvider)
        .where((a) => switch (a.poi.type) {
              ArPoiType.shelter => _showShelters,
              ArPoiType.safeZone => _showSafeZones,
              ArPoiType.riskZone => _showRiskZones,
            })
        .toList();
    final sheltersLoading = ref.watch(
      validatedSheltersProvider.select((a) => a.isLoading),
    );

    return Scaffold(
      body: ArLocationWidget(
        key: ValueKey(_sessionKey),
        annotations: annotations,
        showDebugInfoSensor: false,
        annotationWidth: 210,
        annotationHeight: 62,
        yOffsetOverlap: 12,
        maxVisibleDistance: 2000,
        scaleWithDistance: false,
        radarPosition: RadarPosition.topRight,
        radarWidth: 140,
        isLoading: sheltersLoading,
        onLocationChange: (_) {},
        annotationViewBuilder: (context, annotation) =>
            ArAnnotationCard(annotation: annotation as SalusArAnnotation),
        accessory: SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'ar_close_fab',
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    onPressed: () => context.router.maybePop(),
                    child: const Icon(Icons.close),
                  ),
                  const SizedBox(height: 6),
                  _ArFilterChip(
                    label: 'Refuges',
                    selected: _showShelters,
                    onSelected: (v) => setState(() => _showShelters = v),
                  ),
                  const SizedBox(height: 6),
                  _ArFilterChip(
                    label: 'Zones sûres',
                    selected: _showSafeZones,
                    onSelected: (v) => setState(() => _showSafeZones = v),
                  ),
                  const SizedBox(height: 6),
                  _ArFilterChip(
                    label: 'Zones à risque',
                    selected: _showRiskZones,
                    onSelected: (v) => setState(() => _showRiskZones = v),
                  ),
                ],
              ),
            ),
          ),
        ),
        sensorErrorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  switch (error.type) {
                    ArSensorErrorType.permissionDenied ||
                    ArSensorErrorType.permissionPermanentlyDenied =>
                      'Autorisez la localisation pour orienter les points autour de vous.',
                    ArSensorErrorType.locationServiceDisabled =>
                      'Activez le GPS pour utiliser la vue AR.',
                    ArSensorErrorType.unknown =>
                      'Capteurs indisponibles pour la vue AR.',
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() => _sessionKey++),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de filtre lisible sur la caméra: fond translucide, sélection ambre.
class _ArFilterChip extends StatelessWidget {
  const _ArFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      backgroundColor: Colors.black54,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.bold,
      ),
      selectedColor: AppColors.secondary.withValues(alpha: 0.85),
      side: BorderSide(
        color: selected ? Colors.transparent : Colors.white38,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
