import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/demo/demo_scenario.dart';

void main() {
  test('scénario stable, refuges et zones valides autour du point', () {
    final a = buildDemoScenario(latitude: -18.8792, longitude: 47.5079);
    final b = buildDemoScenario(latitude: -18.8792, longitude: 47.5079);

    expect(a.shelters.length, inInclusiveRange(4, 6));
    expect(a.zones.length, inInclusiveRange(1, 2));

    // Même cellule => même scénario.
    expect(
      a.shelters.map((s) => s.id).toList(),
      b.shelters.map((s) => s.id).toList(),
    );
    expect(
      a.shelters.map((s) => s.location.latitude).toList(),
      b.shelters.map((s) => s.location.latitude).toList(),
    );

    for (final s in a.shelters) {
      expect(s.validationStatus, ValidationStatus.validated);
      expect(s.capacityOccupied, lessThanOrEqualTo(s.capacityTotal));
      expect(s.status, isNot(ShelterStatus.closed));
      expect(s.id, startsWith('demo-'));
    }

    for (final z in a.zones) {
      expect(z.type, ZoneType.risk);
      expect(z.isActive, isTrue);
      expect(z.geometry.length, greaterThanOrEqualTo(3));
    }
  });

  test('un autre secteur produit un scénario différent', () {
    final here = buildDemoScenario(latitude: -18.8792, longitude: 47.5079);
    final far = buildDemoScenario(latitude: 48.8566, longitude: 2.3522);
    expect(
      here.shelters.first.location.latitude,
      isNot(far.shelters.first.location.latitude),
    );
  });

  test('la graine ne dépend pas du hash randomisé d\'un isolate', () {
    // Valeur figée : garde-fou contre un retour à Object.hash (randomisé par
    // run), qui ferait bouger le scénario à chaque lancement de l'app.
    final s = buildDemoScenario(latitude: -18.8792, longitude: 47.5079);
    expect(s.shelters.length, 4);
    expect(s.zones.length, 1);
    expect(s.shelters.first.location.latitude, -18.898928403200188);
    expect(s.zones.first.geometry.first.latitude, -18.84532422987108);
  });
}
