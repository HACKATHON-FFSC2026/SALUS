import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/ar/presentation/models/salus_ar_annotation.dart';
import 'package:salus/features/map/domain/location.dart' as domain;
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/risks/presentation/mappers/zone_ui_mapper.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';

/// ponytail: la grille d'élévation génère jusqu'à 81 zones sûres dans un
/// rayon de ~2 km; en AR on n'affiche que les plus proches. Augmenter
/// [_maxSafeZones] si la victime veut voir plus loin.
const _maxSafeZones = 5;

/// Annotations AR courantes : refuges + zones, déjà filtrées par
/// [buildArAnnotations]. Les zones sûres sont plafonnées aux plus proches
/// de la position connue (sinon la caméra est noyée sous la grille
/// d'élévation).
final arAnnotationsProvider = Provider<List<SalusArAnnotation>>((ref) {
  final shelters =
      ref.watch(validatedSheltersProvider).value ?? const <Shelter>[];
  final riskZones = ref.watch(riskZonesProvider).value ?? const <Zone>[];
  var safeZones = ref.watch(filteredSafeZonesProvider).value ?? const <Zone>[];

  final user = ref.watch(locationProvider.select((s) => s.position));
  if (user != null) {
    final domainUser = domain.GeoPoint(
      latitude: user.latitude,
      longitude: user.longitude,
    );
    double distance(Zone z) =>
        domain.GeoPoint(
          latitude: z.center.latitude,
          longitude: z.center.longitude,
        ).distanceTo(domainUser);
    safeZones = [...safeZones]..sort((a, b) => distance(a).compareTo(distance(b)));
  }
  safeZones = safeZones.take(_maxSafeZones).toList();

  return buildArAnnotations(shelters, riskZones, safeZones);
});
