import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/features/demo/demo_scenario.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';

/// Scénario fictif généré autour de l'utilisateur, pour peupler l'app quand
/// aucune donnée réelle n'est disponible (build de démonstration).
///
/// `null` tant que la position n'est pas connue : hors localisation, pas de
/// données inventées. Le centre est quantifié sur [kDemoCenterCell], donc le
/// scénario reste stable et suit l'utilisateur quand il change de secteur.
final demoScenarioProvider = Provider<DemoScenario?>((ref) {
  final cell = ref.watch(
    locationProvider.select((s) {
      final p = s.position;
      if (p == null) return null;
      return (
        lat: (p.latitude / kDemoCenterCell).round(),
        lng: (p.longitude / kDemoCenterCell).round(),
      );
    }),
  );
  if (cell == null) return null;

  return buildDemoScenario(
    latitude: cell.lat * kDemoCenterCell,
    longitude: cell.lng * kDemoCenterCell,
  );
});
