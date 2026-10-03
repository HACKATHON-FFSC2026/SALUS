import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/core/entities/help_response_entity.dart';
import 'package:salus/core/entities/location_share_entity.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/sos/data/datasources/sos_remote_datasource.dart';
import 'package:salus/features/sos/domain/repositories/sos_repository.dart';
import 'package:salus/features/sos/domain/usecases/offer_help_usecase.dart';
import 'package:salus/features/sos/presentation/providers/responder_controller.dart';

final _now = DateTime(2026, 3, 1, 12);

HelpResponse _response({
  String id = 'a1_r1',
  String responderId = 'r1',
  HelpResponseStatus status = HelpResponseStatus.offered,
}) => HelpResponse(
  id: id,
  sosAlertId: 'a1',
  responderId: responderId,
  responseType: ResponseType.comingInPerson,
  status: status,
  createdAt: _now,
  updatedAt: _now,
);

LocationShare _share({
  String userId = 'r1',
  double lat = -18.8702,
  double lon = 47.5079,
  bool isActive = true,
}) => LocationShare(
  id: 'a1_$userId',
  sosAlertId: 'a1',
  userId: userId,
  currentLocation: GeoPoint(lat, lon),
  isActive: isActive,
  updatedAt: _now,
);

SOSAlert _alert(double lat, double lon) => SOSAlert(
  id: 'a1',
  userId: 'victim',
  distressType: DistressType.other,
  status: SOSStatus.waiting,
  location: GeoPoint(lat, lon),
  createdAt: _now,
  responderIds: const ['r1'],
);

class _FakeRepository implements ISosRepository {
  _FakeRepository({
    List<HelpResponse> responses = const [],
    List<LocationShare> locations = const [],
  })  : _responses = List.of(responses),
        _locations = List.of(locations);

  final List<HelpResponse> _responses;
  final List<LocationShare> _locations;
  final calls = <String>[];

  // Firestore réémet à chaque écriture. Un `Stream.value` figé ne prouverait
  // rien: la victime doit voir un retrait arriver en direct.
  final _responsesCtrl = StreamController<List<HelpResponse>>.broadcast();
  final _locationsCtrl = StreamController<List<LocationShare>>.broadcast();

  Future<void> dispose() async {
    await _responsesCtrl.close();
    await _locationsCtrl.close();
  }

  void _publishLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) {
    final id = responderDocumentId(alertId: alertId, responderId: 'r1');
    final i = _locations.indexWhere((s) => s.id == id);
    final share = _share(lat: latitude, lon: longitude);
    if (i >= 0) {
      _locations[i] = share;
    } else {
      _locations.add(share);
    }
    _locationsCtrl.add(List.of(_locations));
  }

  @override
  Future<void> respondToSos(String alertId) async => calls.add('join:$alertId');

  @override
  Future<String> offerHelp({
    required String alertId,
    ResponseType responseType = ResponseType.comingInPerson,
    String? message,
  }) async {
    calls.add('offer:$alertId:${responseType.name}');
    return responderDocumentId(alertId: alertId, responderId: 'r1');
  }

  @override
  Future<void> setHelpStatus({
    required String responseId,
    required HelpResponseStatus status,
  }) async {
    calls.add('status:$responseId:${status.name}');
    final i = _responses.indexWhere((r) => r.id == responseId);
    if (i >= 0) _responses[i] = _responses[i].copyWith(status: status);
    _responsesCtrl.add(List.of(_responses));
  }

  @override
  Stream<List<HelpResponse>> watchHelpResponses(String alertId) async* {
    yield List.of(_responses);
    yield* _responsesCtrl.stream;
  }

  @override
  Future<void> shareResponderLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) async => _publishLocation(
        alertId: alertId,
        latitude: latitude,
        longitude: longitude,
      );

  @override
  Future<void> stopResponderLocation(String alertId) async {}

  @override
  Stream<List<LocationShare>> watchResponderLocations(String alertId) async* {
    yield List.of(_locations);
    yield* _locationsCtrl.stream;
  }

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
  Stream<SOSAlert?> watchSosAlert(String alertId) => Stream.value(_alert(0, 0));

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts({List<String>? geoCells}) =>
      const Stream.empty();

  @override
  Stream<List<SOSAlert>> watchMyActiveSosAlerts() =>
      Stream.value(List<SOSAlert>.empty());

  @override
  Future<void> shareLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) async {}
}

void main() {
  group('HelpResponse', () {
    test('lit un document Firestore complet', () {
      final response = HelpResponse.fromJson({
        'id': 'a1_r1',
        'responderId': 'r1',
        'sosAlertId': 'a1',
        'responseType': 'comingInPerson',
        'status': 'enRoute',
        'createdAt': Timestamp.fromDate(_now),
        'updatedAt': Timestamp.fromDate(_now),
      });

      expect(response.status, HelpResponseStatus.enRoute);
      expect(response.responseType, ResponseType.comingInPerson);
    });

    test('un statut absent retombe sur offered', () {
      final response = HelpResponse.fromJson({
        'id': 'a1_r1',
        'responderId': 'r1',
        'sosAlertId': 'a1',
        'responseType': 'comingInPerson',
        'createdAt': Timestamp.fromDate(_now),
        'updatedAt': Timestamp.fromDate(_now),
      });

      expect(response.status, HelpResponseStatus.offered);
    });

    test('toJson garde id et createdAt, que les règles n\'interdisent pas',
        () {
      final json = _response().toJson();

      expect(json['id'], 'a1_r1');
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['status'], 'offered');
    });

    test('seul le désistement sort du décompte', () {
      expect(_response().isActive, isTrue);
      expect(
        _response(status: HelpResponseStatus.enRoute).isActive,
        isTrue,
      );
      expect(
        _response(status: HelpResponseStatus.arrived).isActive,
        isTrue,
      );
      expect(
        _response(status: HelpResponseStatus.cancelled).isActive,
        isFalse,
      );
    });
  });

  group('LocationShare', () {
    test('lit un point partagé', () {
      final share = LocationShare.fromJson({
        'id': 'a1_r1',
        'userId': 'r1',
        'sosAlertId': 'a1',
        'currentLocation': const GeoPoint(-18.8792, 47.5079),
        'isActive': true,
        'updatedAt': Timestamp.fromDate(_now),
      });

      expect(share.currentLocation.latitude, closeTo(-18.8792, 1e-9));
      expect(share.isActive, isTrue);
    });

    test('isActive absent vaut vrai', () {
      final share = LocationShare.fromJson({
        'id': 'a1_r1',
        'userId': 'r1',
        'sosAlertId': 'a1',
        'currentLocation': const GeoPoint(0, 0),
        'updatedAt': Timestamp.fromDate(_now),
      });

      expect(share.isActive, isTrue);
    });

    test('toJson émet un GeoPoint', () {
      expect(_share().toJson()['currentLocation'], isA<GeoPoint>());
    });
  });

  group('responderDocumentId', () {
    test('un intervenant a un document par alerte', () {
      expect(
        responderDocumentId(alertId: 'a1', responderId: 'r1'),
        responderDocumentId(alertId: 'a1', responderId: 'r1'),
      );
      expect(
        responderDocumentId(alertId: 'a1', responderId: 'r1'),
        isNot(responderDocumentId(alertId: 'a1', responderId: 'r2')),
      );
      expect(
        responderDocumentId(alertId: 'a1', responderId: 'r1'),
        isNot(responderDocumentId(alertId: 'a2', responderId: 'r1')),
      );
    });
  });

  group('OfferHelpUseCase', () {
    test('rejoint le registre avant de créer le suivi', () async {
      final repo = _FakeRepository();

      final id = await OfferHelpUseCase(repo).execute(alertId: 'a1');

      expect(id, 'a1_r1');
      // L'ordre est une contrainte: les règles n'ouvrent la lecture des
      // suivis qu'à qui figure déjà dans `responderIds`, et c'est
      // `alertHasResponder()` qui autorise la lecture des positions.
      expect(repo.calls, ['join:a1', 'offer:a1:comingInPerson']);
    });

    test('une alerte sans identifiant n\'écrit rien', () async {
      final repo = _FakeRepository();

      expect(await OfferHelpUseCase(repo).execute(alertId: ''), '');
      expect(repo.calls, isEmpty);
    });
  });

  group('distanceInMeters', () {
    test('même point, distance nulle', () {
      expect(
        distanceInMeters(
          alert: _alert(-18.8792, 47.5079),
          location: _share(lat: -18.8792, lon: 47.5079),
        ),
        closeTo(0, 0.001),
      );
    });

    // 0.009 degré de latitude vaut ~1005 m.
    test('un kilomètre au nord', () {
      final meters = distanceInMeters(
        alert: _alert(-18.8792, 47.5079),
        location: _share(lat: -18.8702, lon: 47.5079),
      );

      expect(meters, isNotNull);
      expect(meters, closeTo(1005, 10));
    });

    test('position inconnue ne donne pas de distance inventée', () {
      expect(
        distanceInMeters(alert: _alert(-18.8792, 47.5079), location: null),
        isNull,
      );
    });

    test('la distance est symétrique', () {
      final alert = _alert(-18.8792, 47.5079);
      final forward = distanceInMeters(alert: alert, location: _share());
      final backward = distanceInMeters(
        alert: _alert(-18.8702, 47.5079),
        location: _share(lat: -18.8792, lon: 47.5079),
      );

      expect(forward, isNotNull);
      expect(forward, closeTo(backward!, 0.001));
    });
  });

  group('la victime voit les intervenants', () {
    test('un intervenant qui se retire cesse d\'être compté', () async {
      final repo = _FakeRepository(
        responses: [
          _response(status: HelpResponseStatus.offered),
          _response(
            id: 'a1_r2',
            responderId: 'r2',
            status: HelpResponseStatus.arrived,
          ),
        ],
        locations: [_share()],
      );

      final container = ProviderContainer(
        overrides: [sosRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);
      // Ces providers sont `autoDispose`: sans listener maintenu ouvert, ils
      // sont jetés entre deux lectures et la seconde repart de zéro.
      final responderSub = container.listen(respondersProvider('a1'), (_, _) {});
      final locationSub =
          container.listen(responderLocationsProvider('a1'), (_, _) {});
      addTearDown(() {
        responderSub.close();
        locationSub.close();
      });

      final active = await container.read(respondersProvider('a1').future);
      expect(active, hasLength(2));

      final locations = await container.read(responderLocationsProvider('a1').future);
      expect(locations['r1'], isNotNull);
      expect(
        distanceInMeters(alert: _alert(-18.8792, 47.5079), location: locations['r1']),
        closeTo(1005, 10),
      );

      // L'intervenant se retire: la victime ne le compte plus.
      await SetHelpStatusUseCase(repo).execute(
        responseId: 'a1_r1',
        status: HelpResponseStatus.cancelled,
      );

      final after = await container.read(respondersProvider('a1').future);
      expect(after, hasLength(1));
      expect(after.single.responderId, 'r2');
    });
  });
}
