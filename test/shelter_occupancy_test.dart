import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/shelter_entity.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';

Shelter _shelter({required int total, required int occupied}) => Shelter(
  id: 's1',
  name: 'Refuge',
  location: GeoPoint(-18.87, 47.5),
  address: 'Rue 1',
  capacityTotal: total,
  capacityOccupied: occupied,
  status: ShelterStatus.open,
  resources: const ShelterResources(),
  createdBy: 'u1',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  group('occupancyRatio', () {
    test('représente les places occupées, pas les places libres', () {
      // Le bug d'origine: la barre montrait le ratio disponible, donc un
      // refuge complet affichait une barre vide.
      expect(_shelter(total: 100, occupied: 30).occupancyRatio, closeTo(0.3, 1e-9));
      expect(_shelter(total: 100, occupied: 100).occupancyRatio, 1.0);
      expect(_shelter(total: 100, occupied: 0).occupancyRatio, 0.0);
    });

    test('ne divise pas par zéro et borne le ratio', () {
      expect(_shelter(total: 0, occupied: 0).occupancyRatio, 0.0);
      expect(_shelter(total: 10, occupied: 99).occupancyRatio, 1.0);
    });
  });
}
