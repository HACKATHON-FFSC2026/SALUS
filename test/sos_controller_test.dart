import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/sos/domain/entities/help_response.dart';
import 'package:salus/features/sos/domain/entities/responder_location.dart';
import 'package:salus/features/sos/domain/repositories/sos_repository.dart';
import 'package:salus/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:salus/features/sos/presentation/providers/sos_provider.dart';
import 'package:salus/features/sos/domain/usecases/send_sos_usecase.dart';

/// `SendSosUseCase` sans GPS: le contrôleur est testé, pas le plugin.
class _FakeSendSosUseCase extends SendSosUseCase {
  _FakeSendSosUseCase(this.repo) : super(repo);

  final ISosRepository repo;

  @override
  Future<String> execute({
    DistressType distressType = DistressType.other,
    String? description,
  }) => repo.sendSos(
    latitude: -18.8792,
    longitude: 47.5079,
    distressType: distressType,
    description: description,
  );
}

class _FakeSosRepository implements ISosRepository {
  /// Ce que le flux `watchSosAlert` émettra. `[null]` reproduit un document
  /// disparu, `[alerte]` un document vivant, `[]` un flux silencieux.
  List<SOSAlert?> emissions = const [];

  final cancelled = <String>[];
  final sharedLocations = <Map<String, double>>[];
  final helpStatuses = <String, HelpResponseStatus>{};
  int offers = 0;
  int sent = 0;
  Object? sendThrows;

  /// Bloque `sendSos` pour reproduire la fenêtre entre le geste et l'écriture.
  Completer<void>? sendGate;

  @override
  Future<String> sendSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    if (sendGate != null) await sendGate!.future;
    if (sendThrows != null) throw sendThrows!;
    sent++;
    return 'alert-$sent';
  }

  @override
  Stream<SOSAlert?> watchSosAlert(String alertId) async* {
    for (final emission in emissions) {
      yield emission;
    }
  }

  @override
  Future<void> cancelSos(String alertId) async => cancelled.add(alertId);

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts({List<String>? geoCells}) =>
      const Stream.empty();

  @override
  Stream<List<SOSAlert>> watchMyActiveSosAlerts() =>
      Stream.value(List<SOSAlert>.empty());

  @override
  Future<void> respondToSos(String alertId) async {}

  @override
  Future<String> offerHelp({
    required String alertId,
    HelpResponseType responseType = HelpResponseType.comingInPerson,
    String? message,
  }) async {
    offers++;
    return 'response-$offers';
  }

  @override
  Future<void> setHelpStatus({
    required String responseId,
    required HelpResponseStatus status,
  }) async => helpStatuses[responseId] = status;

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
  }) async => sharedLocations.add({
    'lat': latitude,
    'lng': longitude,
  });
}

SOSAlert _alert({SOSStatus status = SOSStatus.waiting, String id = 'alert-1'}) {
  return SOSAlert(
    id: id,
    userId: 'me',
    location: const GeoPoint(-18.8792, 47.5079),
    distressType: DistressType.medical,
    status: status,
    createdAt: DateTime(2026),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSosRepository fake;
  late ProviderContainer container;

  SosController controller() => container.read(sosControllerProvider.notifier);
  SosState state() => container.read(sosControllerProvider);

  setUp(() {
    fake = _FakeSosRepository();
    container = ProviderContainer(
      overrides: [
        sosRepositoryProvider.overrideWithValue(fake),
        sendSosUseCaseProvider.overrideWithValue(_FakeSendSosUseCase(fake)),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('démarre sans alerte en cours', () {
    expect(state().hasActiveAlert, isFalse);
    expect(state().status, SosStatus.initial);
  });

  // B2: sans l'id renvoyé par l'écriture, la victime ne peut ni suivre son
  // alerte ni l'annuler.
  test('triggerSos conserve l\'id pour le suivi et l\'annulation', () async {
    await controller().triggerSos(distressType: DistressType.fire);

    expect(fake.sent, 1);
    expect(state().alertId, 'alert-1');
    expect(state().hasActiveAlert, isTrue);
    expect(state().status, SosStatus.success);
  });

  // L5: deux maintiens successifs ne doivent pas créer deux alertes.
  test('refuse une seconde alerte tant que la première est active', () async {
    await controller().triggerSos();
    await controller().triggerSos();

    expect(fake.sent, 1);
    expect(state().status, SosStatus.error);
    expect(state().errorMessage, 'Une alerte SOS est déjà en cours.');
  });

  // Deux maintiens quasi simultanés passent tous les deux `hasActiveAlert`,
  // qui ne regarde qu'`alertId` — renseigné après l'écriture. La garde
  // `sending` ferme la fenêtre entre le geste et la création du document.
  test('deux maintiens quasi simultanés ne créent qu\'une alerte', () async {
    fake.sendGate = Completer<void>();

    final first = controller().triggerSos();
    final second = controller().triggerSos();
    fake.sendGate!.complete();
    await Future.wait([first, second]);

    expect(fake.sent, 1);
    expect(state().status, SosStatus.success);
  });

  test('autorise une nouvelle alerte après annulation', () async {
    await controller().triggerSos();
    fake.emissions = [_alert(status: SOSStatus.cancelled)];
    await controller().cancelSos();

    expect(fake.cancelled, ['alert-1']);
    expect(state().hasActiveAlert, isFalse);
  });

  test('cancelSos sur une alerte résolue est sans effet', () async {
    fake.emissions = [_alert(status: SOSStatus.resolved)];
    await controller().triggerSos();
    await Future<void>.delayed(Duration.zero);

    await controller().cancelSos();

    expect(fake.cancelled, isEmpty);
  });

  // L7: un citoyen qui répond ne bascule pas l'alerte en « secours en route ».
  test('le flux temps réel pilote le statut affiché', () async {
    fake.emissions = [_alert(status: SOSStatus.inProgress, id: 'alert-1')];
    await controller().triggerSos();
    await Future<void>.delayed(Duration.zero);

    expect(state().alert?.status, SOSStatus.inProgress);
    expect(state().hasActiveAlert, isTrue);
  });

  test('une alerte disparue du serveur ne reste pas « en cours »', () async {
    fake.emissions = [null];
    await controller().triggerSos();
    await Future<void>.delayed(Duration.zero);

    expect(state().alertId, isNull);
    expect(state().hasActiveAlert, isFalse);
  });

  test('propage le message d\'échec sans « Exception: »', () async {
    fake.sendThrows = Exception('Permission de localisation refusée.');

    await controller().triggerSos();

    expect(state().status, SosStatus.error);
    expect(state().errorMessage, 'Permission de localisation refusée.');
    expect(state().alertId, isNull);
  });
}
