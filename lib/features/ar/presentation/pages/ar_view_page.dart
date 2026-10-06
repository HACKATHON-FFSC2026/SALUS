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

class _ArViewPageState extends ConsumerState<ArViewPage>
    with SingleTickerProviderStateMixin {
  // ponytail: clé forcée pour « Réessayer » après refus de permission;
  // ArLocationWidget possèdera son flux capteurs et doit être recréé.
  int _sessionKey = 0;
  late final AnimationController _pulseController;

  /// Filtres par type. Zones à risque masquées par défaut: sur le terrain,
  /// on cherche d'abord où aller, pas où ne pas aller (spec §1.1).
  bool _showShelters = true;
  bool _showSafeZones = true;
  bool _showRiskZones = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulseController
        ..stop()
        ..value = 0;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final annotations = ref
        .watch(arAnnotationsProvider)
        .where(
          (a) => switch (a.poi.type) {
            ArPoiType.shelter => _showShelters,
            ArPoiType.safeZone => _showSafeZones,
            ArPoiType.riskZone => _showRiskZones,
          },
        )
        .toList();
    final sheltersLoading = ref.watch(
      validatedSheltersProvider.select((a) => a.isLoading),
    );

    return Scaffold(
      body: ArLocationWidget(
        key: ValueKey(_sessionKey),
        annotations: annotations,
        showDebugInfoSensor: false,
        annotationWidth: ArAnnotationCard.width,
        annotationHeight: ArAnnotationCard.height,
        yOffsetOverlap: 12,
        maxVisibleDistance: 2000,
        scaleWithDistance: false,
        showRadar: false,
        isLoading: sheltersLoading,
        onLocationChange: (_) {},
        annotationViewBuilder: (context, annotation) => ArAnnotationCard(
          annotation: annotation as SalusArAnnotation,
          pulse: _pulseController,
        ),
        accessory: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: FloatingActionButton.small(
                  heroTag: 'ar_close_fab',
                  backgroundColor: Colors.black.withValues(alpha: 0.72),
                  foregroundColor: Colors.white,
                  onPressed: () => context.router.maybePop(),
                  tooltip: 'Fermer la vue AR',
                  child: const Icon(Icons.close),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  label: '${annotations.length} points d’intérêt visibles',
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Text(
                      '${annotations.length}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ArFilterButton(
                      label: 'Refuges',
                      icon: Icons.night_shelter_outlined,
                      selected: _showShelters,
                      onPressed: () =>
                          setState(() => _showShelters = !_showShelters),
                    ),
                    const SizedBox(width: 18),
                    _ArFilterButton(
                      label: 'Zones sûres',
                      icon: Icons.health_and_safety_outlined,
                      selected: _showSafeZones,
                      onPressed: () =>
                          setState(() => _showSafeZones = !_showSafeZones),
                    ),
                    const SizedBox(width: 18),
                    _ArFilterButton(
                      label: 'Zones à risque',
                      icon: Icons.warning_amber_rounded,
                      selected: _showRiskZones,
                      onPressed: () =>
                          setState(() => _showRiskZones = !_showRiskZones),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        sensorErrorBuilder: (context, error) {
          final message = switch (error.type) {
            ArSensorErrorType.permissionDenied ||
            ArSensorErrorType.permissionPermanentlyDenied =>
              'Autorisez la localisation pour orienter les points autour de vous.',
            ArSensorErrorType.locationServiceDisabled =>
              'Activez le GPS pour utiliser la vue AR.',
            ArSensorErrorType.unknown =>
              'Capteurs indisponibles pour la vue AR.',
          };
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_searching,
                          color: AppColors.secondary,
                          size: 32,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Vue AR indisponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: () => setState(() => _sessionKey++),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArFilterButton extends StatelessWidget {
  const _ArFilterButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label ${selected ? 'activés' : 'masqués'}',
      child: Semantics(
        label: label,
        button: true,
        toggled: selected,
        child: Material(
          color: selected
              ? AppColors.secondary
              : Colors.black.withValues(alpha: 0.72),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(
                icon,
                color: selected ? Colors.black : Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
