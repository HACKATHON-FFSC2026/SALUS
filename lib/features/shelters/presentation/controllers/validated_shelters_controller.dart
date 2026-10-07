import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/demo/demo_scenario_provider.dart';
import 'package:salus/features/shelters/domain/usecases/find_shelters_in_risk_zones.dart';

final findSheltersInRiskZonesProvider = Provider<FindSheltersInRiskZones>(
  (ref) => FindSheltersInRiskZones(ref.watch(geofenceServiceProvider)),
);

/// Refuges validés affichés sur la carte, alimentés en temps réel par
/// Firestore.
///
/// Un unique flux alimente tous les markers : pas de requête par refuge.
final validatedSheltersProvider = StreamProvider<List<Shelter>>((ref) {
  final base = ref
      .watch(shelterRepositoryProvider)
      .watchValidatedShelters()
      .handleError((Object error, StackTrace stackTrace) {
        Log.error('Échec du chargement des refuges validés', error, stackTrace);
        throw error;
      });
  return _withDemoShelters(ref, base);
});

/// Tous les statuts de validation pour la liste de refuges. La carte utilise
/// toujours [validatedSheltersProvider] afin de ne montrer que les refuges
/// validés.
final allSheltersProvider = StreamProvider<List<Shelter>>((ref) {
  final base = ref
      .watch(shelterRepositoryProvider)
      .watchAllShelters()
      .handleError((Object error, StackTrace stackTrace) {
        Log.error(
          'Échec du chargement de la liste des refuges',
          error,
          stackTrace,
        );
        throw error;
      });
  return _withDemoShelters(ref, base);
});

/// Ajoute les refuges fictifs de démonstration aux refuges réels.
///
/// No-op sans scénario actif (position inconnue) : les tests et un premier
/// lancement sans GPS gardent le flux intact.
Stream<List<Shelter>> _withDemoShelters(
  Ref ref,
  Stream<List<Shelter>> base,
) {
  final demo = ref.watch(demoScenarioProvider)?.shelters;
  if (demo == null || demo.isEmpty) return base;
  return base.map((shelters) => [...shelters, ...demo]);
}
