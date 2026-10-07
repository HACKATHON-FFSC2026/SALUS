import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/demo/demo_scenario_provider.dart';

/// Zones à risque actives, diffusées en direct depuis Firestore.
final activeRiskZonesProvider = StreamProvider<List<Zone>>((ref) {
  final base = ref
      .watch(firestoreRiskZoneRepositoryProvider)
      .watchActiveRiskZones()
      .handleError((Object error, StackTrace stackTrace) {
        Log.error('Échec du chargement des zones à risque', error, stackTrace);
        throw error;
      });

  // ponytail: zones fictives de démonstration, aucune tant que le GPS est
  // inconnu. Les ids `demo-` se dédupliquent avec les sources réelles.
  final demo = ref.watch(demoScenarioProvider)?.zones;
  if (demo == null || demo.isEmpty) return base;
  return base.map((zones) => [...zones, ...demo]);
});
