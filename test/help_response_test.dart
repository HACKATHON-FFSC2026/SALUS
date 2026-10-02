import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/sos/domain/entities/help_response.dart';
import 'package:salus/features/sos/domain/entities/responder_location.dart';
import 'package:salus/features/sos/domain/repositories/sos_repository.dart';
import 'package:salus/features/sos/domain/usecases/offer_help_usecase.dart';
import 'package:salus/features/sos/presentation/providers/responder_controller.dart';

class _RecordingRepository implements ISosRepository {
  final calls = <String>[];

  @override
  Future<void> respondToSos(String alertId) async => calls.add('join:$alertId');

  @override
  Future<String> offerHelp({
    required String alertId,
    HelpResponseType responseType = HelpResponseType.comingInPerson,
    String? message,
  }) async {
    calls.add('offer:$alertId:${responseType.name}');
    return 'response-1';
  }

  @override
  Future<void> setHelpStatus({
    required String responseId,
    required HelpResponseStatus status,
  }) async => calls.add('status:$responseId:${status.name}');

  @override
  Future<String> sendSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) async => 'alert-1';

  @override
  Future<void> cancelSos(String alertId) async {}

  @override
  Stream<SOSAlert?> watchSosAlert(String alertId) => const Stream.empty();

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts({List<String>? geoCells}) =>
      const Stream.empty();

  @override
  Stream<List<SOSAlert>> watchMyActiveSosAlerts() =>
      Stream.value(List<SOSAlert>.empty());

  @override
  Stream<List<HelpResponse>> watchHelpResponses(String alertId) =>
      const Stream.empty();

  @override
  Future<void> shareResponderLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) async {}

  @override
  Future<void> stopResponderLocation(String alertId) async {}

  @override
  Stream<List<ResponderLocation>> watchResponderLocations(String alertId) =>
      const Stream.empty();

  @override
  Future<void> shareLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) async {}
}

void main() {
  group('OfferHelpUseCase', () {
    test('rejoint le registre avant de créer le suivi', () async {
      final repo = _RecordingRepository();

      final id = await OfferHelpUseCase(repo).execute(alertId: 'a1');

      expect(id, 'response-1');
      // L'ordre est une contrainte, pas un détail: les règles n'ouvrent la
      // lecture des suivis qu'à qui figure déjà dans `responderIds`.
      expect(repo.calls, ['join:a1', 'offer:a1:comingInPerson']);
    });

    test('une alerte sans identifiant n\'écrit rien', () async {
      final repo = _RecordingRepository();

      final id = await OfferHelpUseCase(repo).execute(alertId: '');

      expect(id, '');
      expect(repo.calls, isEmpty);
    });

    test('un conseil texte porte son message', () async {
      final repo = _RecordingRepository();

      await OfferHelpUseCase(repo).execute(
        alertId: 'a1',
        responseType: HelpResponseType.textAdvice,
        message: 'Restez allongée, ne bougez pas le cou.',
      );

      expect(repo.calls.last, 'offer:a1:textAdvice');
    });
  });

  group('SetHelpStatusUseCase', () {
    test('le désistement passe par cancelled', () async {
      final repo = _RecordingRepository();

      await SetHelpStatusUseCase(repo).execute(
        responseId: 'response-1',
        status: HelpResponseStatus.cancelled,
      );

      expect(repo.calls, ['status:response-1:cancelled']);
    });

    test('sans identifiant de suivi, rien n\'est écrit', () async {
      final repo = _RecordingRepository();

      await SetHelpStatusUseCase(repo).execute(
        responseId: '',
        status: HelpResponseStatus.enRoute,
      );

      expect(repo.calls, isEmpty);
    });
  });

  group('distanceInMeters', () {
    SOSAlert alertAt(double lat, double lon) => SOSAlert(
      id: 'a1',
      userId: 'victim',
      distressType: DistressType.other,
      status: SOSStatus.waiting,
      location: GeoPoint(lat, lon),
      createdAt: DateTime.now(),
      responderIds: const [],
    );

    test('même point, distance nulle', () {
      expect(
        distanceInMeters(
          alert: alertAt(-18.8792, 47.5079),
          location: ResponderLocation(
            userId: 'u2',
            sosAlertId: 'a1',
            latitude: -18.8792,
            longitude: 47.5079,
          ),
        ),
        closeTo(0, 0.001),
      );
    });

    // ~1 km au nord: 0.009 degré de latitude vaut ~1005 m.
    test('un kilomètre au nord', () {
      final meters = distanceInMeters(
        alert: alertAt(-18.8792, 47.5079),
        location: ResponderLocation(
          userId: 'u2',
          sosAlertId: 'a1',
          latitude: -18.8702,
          longitude: 47.5079,
        ),
      );

      expect(meters, isNotNull);
      expect(meters!, closeTo(1005, 10));
    });

    test('position inconnue ne donne pas de distance inventée', () {
      expect(
        distanceInMeters(alert: alertAt(-18.8792, 47.5079), location: null),
        isNull,
      );
    });

    test('la distance est symétrique', () {
      final a = alertAt(-18.8792, 47.5079);
      final b = ResponderLocation(
        userId: 'u2',
        sosAlertId: 'a1',
        latitude: -18.7,
        longitude: 47.4,
      );

      final forward = distanceInMeters(alert: a, location: b);
      final backward = distanceInMeters(
        alert: alertAt(-18.7, 47.4),
        location: ResponderLocation(
          userId: 'v',
          sosAlertId: 'a1',
          latitude: a.location.latitude,
          longitude: a.location.longitude,
        ),
      );

      expect(forward, isNotNull);
      expect(forward, closeTo(backward!, 0.001));
    });
  });

  group('HelpResponse', () {
    test('lit un document Firestore complet', () {
      final response = HelpResponse.fromJson({
        'responderId': 'u1',
        'sosAlertId': 'a1',
        'responseType': 'comingInPerson',
        'status': 'enRoute',
        'message': 'J\'arrive',
        'updatedAt': Timestamp.fromDate(DateTime(2026)),
      }, fallbackId: 'r1');

      expect(response.id, 'r1');
      expect(response.responderId, 'u1');
      expect(response.sosAlertId, 'a1');
      expect(response.responseType, HelpResponseType.comingInPerson);
      expect(response.status, HelpResponseStatus.enRoute);
      expect(response.message, 'J\'arrive');
      expect(response.isActive, isTrue);
    });

    test('retombe sur offered et comingInPerson si le statut est inconnu', () {
      final response = HelpResponse.fromJson({
        'responderId': 'u1',
        'sosAlertId': 'a1',
        'responseType': 'n\'importe quoi',
        'status': 'statut inventé',
      });

      expect(response.responseType, HelpResponseType.comingInPerson);
      expect(response.status, HelpResponseStatus.offered);
    });

    test('un document vide est rejeté', () {
      expect(() => HelpResponse.fromJson(null), throwsFormatException);
    });

    test('un intervenant a un seul suivi par alerte', () {
      expect(
        HelpResponse.documentIdFor(alertId: 'a1', responderId: 'u1'),
        HelpResponse.documentIdFor(alertId: 'a1', responderId: 'u1'),
      );
      expect(
        HelpResponse.documentIdFor(alertId: 'a1', responderId: 'u1'),
        isNot(HelpResponse.documentIdFor(alertId: 'a1', responderId: 'u2')),
      );
      expect(
        HelpResponse.documentIdFor(alertId: 'a1', responderId: 'u1'),
        isNot(HelpResponse.documentIdFor(alertId: 'a2', responderId: 'u1')),
      );
    });

    // `toJson` fige `status` à `offered`, sinon une ré-écriture ferait
    // régresser un intervenant déjà arrivé.
    test('la création est toujours annoncée comme offered', () {
      const response = HelpResponse(
        id: 'r1',
        responderId: 'u1',
        sosAlertId: 'a1',
        responseType: HelpResponseType.comingInPerson,
        status: HelpResponseStatus.arrived,
      );

      expect(response.toJson()['status'], 'offered');
      expect(response.toJson()['responderId'], 'u1');
      expect(response.toJson()['sosAlertId'], 'a1');
    });

    test('seul le désistement sort du décompte des intervenants', () {
      expect(HelpResponseStatus.offered.isActive, isTrue);
      expect(HelpResponseStatus.enRoute.isActive, isTrue);
      expect(HelpResponseStatus.arrived.isActive, isTrue);
      expect(HelpResponseStatus.cancelled.isActive, isFalse);
    });

    test('arrived marque l\'intervenant sur place', () {
      expect(HelpResponseStatus.arrived.isOnSite, isTrue);
      expect(HelpResponseStatus.enRoute.isOnSite, isFalse);
    });
  });

  group('ResponderLocation', () {
    test('lit un document de partage de position', () {
      final location = ResponderLocation.fromJson({
        'userId': 'u2',
        'sosAlertId': 'a1',
        'currentLocation': const GeoPoint(-18.8792, 47.5079),
        'updatedAt': Timestamp.fromDate(DateTime(2026)),
        'isActive': true,
      });

      expect(location.userId, 'u2');
      expect(location.latitude, closeTo(-18.8792, 1e-9));
      expect(location.longitude, closeTo(47.5079, 1e-9));
      expect(location.isActive, isTrue);
    });

    test('refuse une position sans coordonnées', () {
      expect(
        () => ResponderLocation.fromJson({'userId': 'u2', 'currentLocation': 'ici'}),
        throwsFormatException,
      );
    });

    // Un point arrêté depuis plusieurs minutes ne doit pas passer pour une
    // position vivante.
    test('une position périmée est signalée comme telle', () {
      final stale = ResponderLocation(
        userId: 'u2',
        sosAlertId: 'a1',
        latitude: 0,
        longitude: 0,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      final fresh = ResponderLocation(
        userId: 'u2',
        sosAlertId: 'a1',
        latitude: 0,
        longitude: 0,
        updatedAt: DateTime.now(),
      );

      expect(stale.isStale, isTrue);
      expect(fresh.isStale, isFalse);
    });

    test('un partage arrêté reste connu mais n\'est plus actif', () {
      final stopped = ResponderLocation(
        userId: 'u2',
        sosAlertId: 'a1',
        latitude: 1,
        longitude: 2,
        isActive: false,
      );

      expect(stopped.isActive, isFalse);
    });

    test('un intervenant a un seul document par alerte', () {
      expect(
        ResponderLocation.documentIdFor(alertId: 'a1', userId: 'u2'),
        ResponderLocation.documentIdFor(alertId: 'a1', userId: 'u2'),
      );
      expect(
        ResponderLocation.documentIdFor(alertId: 'a1', userId: 'u2'),
        isNot(ResponderLocation.documentIdFor(alertId: 'a1', userId: 'u3')),
      );
      expect(
        ResponderLocation.documentIdFor(alertId: 'a1', userId: 'u2'),
        isNot(ResponderLocation.documentIdFor(alertId: 'a2', userId: 'u2')),
      );
    });

    test('le partage sérialise un GeoPoint et un horodatage serveur', () {
      final location = ResponderLocation(
        userId: 'u2',
        sosAlertId: 'a1',
        latitude: -18.8792,
        longitude: 47.5079,
      );

      final json = location.toJson();
      expect(json['currentLocation'], isA<GeoPoint>());
      expect(json['isActive'], isTrue);
      expect(json['updatedAt'], isA<FieldValue>());
    });
  });
}