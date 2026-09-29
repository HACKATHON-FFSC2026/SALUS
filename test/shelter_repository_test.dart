import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/shelters/data/shelter_repository.dart';

/// Document Firestore tel qu'écrit par `createShelter` (cf. test de création).
Map<String, dynamic> _document({
  String? id = 'shelter-1',
  String status = 'open',
  String validationStatus = 'validated',
}) {
  return <String, dynamic>{
    if (id != null) 'id': id,
    'name': 'Refuge Mahamasina',
    'location': const GeoPoint(-18.8792, 47.5079),
    'address': 'Mahamasina, Antananarivo',
    'capacityTotal': 50,
    'capacityOccupied': 12,
    'status': status,
    'resources': <String, Object?>{
      'water': true,
      'food': true,
      'electricity': false,
      'medicalKit': false,
    },
    'photos': const <String>[],
    'createdBy': 'user-1',
    'validationStatus': validationStatus,
    'unsafeReportsCount': 0,
    'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
  };
}

void main() {
  group('FirestoreShelterRepository.decodeShelter', () {
    test('convertit un document Firestore en Shelter', () {
      final shelter = FirestoreShelterRepository.decodeShelter(
        'doc-1',
        _document(),
      );

      expect(shelter, isNotNull);
      expect(shelter!.id, 'shelter-1');
      expect(shelter.name, 'Refuge Mahamasina');
      expect(shelter.location.latitude, -18.8792);
      expect(shelter.location.longitude, 47.5079);
      expect(shelter.address, 'Mahamasina, Antananarivo');
      expect(shelter.capacityOccupied, 12);
      expect(shelter.capacityTotal, 50);
      expect(shelter.status, ShelterStatus.open);
      expect(shelter.resources.water, isTrue);
      expect(shelter.resources.food, isTrue);
      expect(shelter.resources.electricity, isFalse);
      expect(shelter.resources.medicalKit, isFalse);
      expect(shelter.validationStatus, ValidationStatus.validated);
      expect(shelter.createdAt, DateTime(2026, 1, 1));
      expect(shelter.updatedAt, DateTime(2026, 1, 2));
    });

    test('retombe sur l\'identifiant du document si le champ id manque', () {
      final shelter = FirestoreShelterRepository.decodeShelter(
        'doc-42',
        _document(id: null),
      );

      expect(shelter?.id, 'doc-42');
    });

    test('ignore un document incomplet sans casser les autres', () {
      final shelter = FirestoreShelterRepository.decodeShelter(
        'doc-1',
        <String, dynamic>{'name': 'Refuge sans statut'},
      );

      expect(shelter, isNull);
    });
  });
}
