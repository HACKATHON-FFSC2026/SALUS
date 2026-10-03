import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/ar/presentation/models/salus_ar_annotation.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';

/// Annotations AR courantes : refuges + zones, déjà filtrées par
/// [buildArAnnotations].
final arAnnotationsProvider = Provider<List<SalusArAnnotation>>((ref) {
  final shelters =
      ref.watch(validatedSheltersProvider).value ?? const <Shelter>[];
  final riskZones = ref.watch(riskZonesProvider).value ?? const <Zone>[];
  final safeZones =
      ref.watch(filteredSafeZonesProvider).value ?? const <Zone>[];
  return buildArAnnotations(shelters, riskZones, safeZones);
});
