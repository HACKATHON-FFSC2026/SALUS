import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/utils/geo_grid.dart';
import 'package:salus/features/sos/domain/entities/emergency_numbers.dart';

/// Document Firestore tel qu'écrit par `createSosAlert`.
Map<String, dynamic> _document({
  String id = 'alert-1',
  String userId = 'victim-1',
  String status = 'waiting',
  Object? location = const GeoPoint(-18.8792, 47.5079),
  List<String> responderIds = const [],
}) {
  return <String, dynamic>{
    'id': id,
    'userId': userId,
    'location': ?location,
    'geoCell': GeoGrid.cellFor(-18.8792, 47.5079),
    'distressType': 'medical',
    'description': 'Personne inconsciente',
    'status': status,
    'responderIds': responderIds,
    'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    'locationUpdatedAt': Timestamp.fromDate(DateTime(2026, 1, 1, 0, 0, 5)),
  };
}

void main() {
  group('SOSAlert.fromJson', () {
    test('convertit un document Firestore', () {
      final alert = SOSAlert.fromJson(_document(responderIds: ['a', 'b']));

      expect(alert.id, 'alert-1');
      expect(alert.userId, 'victim-1');
      expect(alert.distressType, DistressType.medical);
      expect(alert.status, SOSStatus.waiting);
      expect(alert.description, 'Personne inconsciente');
      expect(alert.respondersCount, 2);
      expect(alert.locationUpdatedAt, DateTime(2026, 1, 1, 0, 0, 5));
    });

    // L2: une alerte sans position exploitable est plus dangereuse qu'une
    // alerte absente. Elle géolocalisée à (0, 0) apparaît à 15 000 km.
    test('refuse un document sans position plutôt que de le mettre à (0,0)', () {
      expect(
        () => SOSAlert.fromJson(_document(location: null)),
        throwsFormatException,
      );
      expect(
        () => SOSAlert.fromJson(_document(location: 'nan')),
        throwsFormatException,
      );
      expect(() => SOSAlert.fromJson(null), throwsFormatException);
    });

    test('retombe sur other/waiting sur un statut inconnu', () {
      final alert = SOSAlert.fromJson({
        ..._document(),
        'distressType': 'nuclear',
        'status': 'exploded',
      });

      expect(alert.distressType, DistressType.other);
      expect(alert.status, SOSStatus.waiting);
    });

    // L4: distanceInKm doit survivre à un aller-retour, sinon le tri par
    // proximité casse dès que le document repasse par Firestore.
    test('distanceInKm est un champ client, jamais persisté ni relu', () {
      final alert = SOSAlert.fromJson(_document())
          .withDistanceFrom(latitude: -18.8792, longitude: 47.5079);

      expect(alert.distanceInKm, closeTo(0, 0.001));
      expect(alert.toJson().containsKey('distanceInKm'), isFalse);
      expect(SOSAlert.fromJson(alert.toJson()).distanceInKm, isNull);
    });

    test('copyWith peut effacer la distance', () {
      final alert = SOSAlert.fromJson(_document())
          .withDistanceFrom(latitude: -18.0, longitude: 47.0);

      expect(alert.copyWith(clearDistance: true).distanceInKm, isNull);
    });
  });

  group('SOSAlert.withDistanceFrom', () {
    test('mesure une distance cohérente', () {
      // Antananarivo -> Toamasina, ~215 km à vol d'oiseau.
      final alert = SOSAlert(
        id: 'a',
        userId: 'v',
        location: const GeoPoint(-18.8792, 47.5079),
        distressType: DistressType.other,
        status: SOSStatus.waiting,
        createdAt: DateTime(2026),
      ).withDistanceFrom(latitude: -18.1443, longitude: 49.3958);

      expect(alert.distanceInKm, closeTo(215, 5));
    });

    test('vaut zéro sur la position même', () {
      final alert = SOSAlert(
        id: 'a',
        userId: 'v',
        location: const GeoPoint(10, 20),
        distressType: DistressType.other,
        status: SOSStatus.waiting,
        createdAt: DateTime(2026),
      ).withDistanceFrom(latitude: 10, longitude: 20);

      expect(alert.distanceInKm, closeTo(0, 0.0001));
    });
  });

  group('SOSStatus', () {
    test('isActive couvre waiting et inProgress seulement', () {
      expect(SOSStatus.waiting.isActive, isTrue);
      expect(SOSStatus.inProgress.isActive, isTrue);
      expect(SOSStatus.resolved.isActive, isFalse);
      expect(SOSStatus.cancelled.isActive, isFalse);
      expect(SOSStatus.cancelled.isOver, isTrue);
    });
  });

  group('GeoGrid', () {
    test('cellule stable et distincte par zone', () {
      expect(
        GeoGrid.cellFor(-18.8792, 47.5079),
        GeoGrid.cellFor(-18.8800, 47.5080),
      );
      expect(
        GeoGrid.cellFor(-18.8792, 47.5079),
        isNot(GeoGrid.cellFor(-18.92, 47.55)),
      );
    });

    test('cellsAround couvre un carré 3x3', () {
      final cells = GeoGrid.cellsAround(-18.8792, 47.5079);

      // -18.8792 / 0.02 -> -944, 47.5079 / 0.02 -> 2375.
      expect(GeoGrid.cellFor(-18.8792, 47.5079), '-944:2375');
      expect(cells, hasLength(9));
      expect(cells, contains('-944:2375'));
      // Voisines: une cellule au nord-est du centre.
      expect(cells, contains('-943:2376'));
      // Au-delà de 3x3, hors requête.
      expect(cells, isNot(contains('-946:2377')));
    });
  });

  group('EmergencyNumbers', () {
    test('résout le pays sans tenir compte de la casse', () {
      expect(EmergencyNumbers.forCountry('madagascar').police, '117');
      expect(EmergencyNumbers.forCountry('Madagascar').fire, '118');
      expect(EmergencyNumbers.forCountry('France').ambulance, '15');
    });

    // Mieux vaut un 112 qui redirige qu'un numéro deviné.
    test('retombe sur 112 pour un pays inconnu', () {
      final unknown = EmergencyNumbers.forCountry('ZLAN');

      expect(unknown.police, '112');
      expect(unknown.fire, '112');
      expect(EmergencyNumbers.forCountry(null).police, '112');
    });
  });

  group('comportement de l\'écriture', () {
    // L1: le comptage part des uid, jamais d'un incrément. C'est ce qui rend
    // « deux taps » idempotent.
    test('respondersCount dérive de responderIds, pas d\'un compteur stocké', () {
      final alert = SOSAlert.fromJson(
        _document(responderIds: const ['a']),
      );

      expect(alert.respondersCount, 1);
      expect(
        alert.copyWith(responderIds: const ['a', 'a']).respondersCount,
        2,
        reason: 'arrayUnion côté Firestore déduplique, le modèle ne double rien',
      );
      expect(alert.copyWith(responderIds: const []).respondersCount, 0);
    });

    test('un document sans responderIds vaut zéro intervenant', () {
      final alert = SOSAlert.fromJson({
        ..._document(),
      }..remove('responderIds'));

      expect(alert.respondersCount, 0);
    });
  });
}