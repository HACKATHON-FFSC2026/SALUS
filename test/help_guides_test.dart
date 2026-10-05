import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/features/help/domain/entities/evacuation_guidelines.dart';
import 'package:salus/features/sos/domain/entities/first_aid_guidelines.dart';

void main() {
  test('évacuation: les 4 MUST du spec ont des consignes', () {
    for (final type in [
      DisasterType.earthquake,
      DisasterType.tsunami,
      DisasterType.cyclone,
      DisasterType.flood,
    ]) {
      final guideline = EvacuationGuides.forType(type);
      expect(guideline.steps.length, greaterThanOrEqualTo(3),
          reason: '$type doit avoir des consignes d\'évacuation');
    }
  });

  test('évacuation: fallback général pour un type non couvert', () {
    expect(
      EvacuationGuides.forType(DisasterType.other).title,
      contains('générales'),
    );
  });

  test('chips: tous les types ordonnés résolvent un guide', () {
    for (final type in EvacuationGuides.orderedTypes) {
      expect(EvacuationGuides.forType(type).title, isNotEmpty);
    }
    expect(EvacuationGuides.orderedTypes.toSet().length,
        EvacuationGuides.orderedTypes.length);
  });

  test('premiers secours: une consigne par type de détresse', () {
    for (final type in DistressType.values) {
      expect(FirstAidGuideline.getGuidelinesFor(type).steps, isNotEmpty);
    }
  });
}
