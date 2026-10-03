import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/auth/domain/auth_repository.dart';
import 'package:salus/features/auth/domain/user_profile.dart';
import 'package:salus/core/entities/help_response_entity.dart';
import 'package:salus/core/entities/location_share_entity.dart';
import 'package:salus/features/sos/domain/repositories/sos_repository.dart';
import 'package:salus/features/sos/domain/usecases/send_sos_usecase.dart';
import 'package:salus/features/sos/presentation/pages/sos_page.dart';
import 'package:salus/features/sos/presentation/providers/sos_provider.dart';
import 'package:salus/features/sos/presentation/widgets/sos_button.dart';

class _GuestAuthRepository implements AuthRepository {
  @override
  String? get currentUserId => null;

  @override
  UserProfile? get currentProfile => null;

  @override
  Future<UserProfile?> signInWithGoogle() async => null;

  @override
  Future<void> syncProfile(UserProfile profile) async {}

  @override
  Future<void> continueAsGuest() async {}

  @override
  Future<bool> hasAccount() async => true;

  @override
  Future<void> signOut() async {}
}

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
  _FakeSosRepository({this.myAlert, this.responses = const [], this.locations = const []});

  /// Alerte dont la victime est propriétaire: c'est ce qui fait basculer la
  /// page en vue « alerte ouverte ».
  final SOSAlert? myAlert;
  final List<HelpResponse> responses;
  final List<LocationShare> locations;

  int sent = 0;

  @override
  Future<String> sendSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    sent++;
    return 'alert-$sent';
  }

  @override
  Future<void> cancelSos(String alertId) async {}

  @override
  Future<void> respondToSos(String alertId) async {}

  @override
  Future<String> offerHelp({
    required String alertId,
    ResponseType responseType = ResponseType.comingInPerson,
    String? message,
  }) async => 'response-1';

  @override
  Future<void> setHelpStatus({
    required String responseId,
    required HelpResponseStatus status,
  }) async {}

@override
  Stream<List<HelpResponse>> watchHelpResponses(String alertId) =>
      Stream.value(responses);

  @override
  Future<void> shareResponderLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) async {}

  @override
  Future<void> stopResponderLocation(String alertId) async {}

  @override
  Stream<List<LocationShare>> watchResponderLocations(String alertId) =>
      Stream.value(locations);

  @override
  Future<void> shareLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) async {}

  @override
  Stream<SOSAlert?> watchSosAlert(String alertId) => const Stream.empty();

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts({List<String>? geoCells}) =>
      const Stream.empty();

@override
  Stream<List<SOSAlert>> watchMyActiveSosAlerts() =>
      Stream.value(myAlert == null ? const <SOSAlert>[] : [myAlert!]);
}

/// Un invité en détresse doit pouvoir appeler quelqu'un. Masquer les numéros
/// derrière un mur de connexion rendait l'app inutile dans l'urgence.
/// Écrans où la page doit rester lisible sans débordement.
/// 411x891 est la référence « petit écran » retenue par `app_smoke_test`.
const _screenSizes = [Size(411, 891), Size(360, 640)];

void main() {
  late _FakeSosRepository repo;

  Future<void> pumpGuest(WidgetTester tester) async {
    // Viewport large: la page doit tenir sans défiler, les numéros sont en
    // bas de l'écran et doivent rester atteignables.
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repo = _FakeSosRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_GuestAuthRepository()),
          sosRepositoryProvider.overrideWithValue(repo),
          sendSosUseCaseProvider.overrideWithValue(_FakeSendSosUseCase(repo)),
        ],
        child: const MaterialApp(home: SosPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('un invité voit les numéros d\'urgence', (tester) async {
    await pumpGuest(tester);

    expect(find.text('Appeler les secours'), findsOneWidget);
    expect(find.text('117'), findsOneWidget);
    expect(find.text('118'), findsOneWidget);
    expect(find.text('Identifiez-vous pour envoyer un SOS'), findsNothing);
  });

  testWidgets('un invité voit le bouton mais ne peut pas l\'actionner', (
    tester,
  ) async {
    await pumpGuest(tester);

    expect(find.byType(SosButton), findsOneWidget);
    final button = tester.widget<SosButton>(find.byType(SosButton));
    expect(button.isEnabled, isFalse);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SosButton)),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repo.sent, 0, reason: 'un invité ne doit rien pouvoir envoyer');
  });

  for (final size in _screenSizes) {
    testWidgets('tient sur ${size.width}x${size.height} sans déborder', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      repo = _FakeSosRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_GuestAuthRepository()),
            sosRepositoryProvider.overrideWithValue(repo),
            sendSosUseCaseProvider.overrideWithValue(_FakeSendSosUseCase(repo)),
          ],
          child: const MaterialApp(home: SosPage()),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Les numéros doivent rester atteignables, pas seulement construit.
      expect(find.text('Appeler les secours'), findsOneWidget);
    });
  }

  testWidgets('la victime voit qui intervient et à quelle distance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final alert = SOSAlert(
      id: 'a1',
      userId: 'victim',
      distressType: DistressType.other,
      status: SOSStatus.waiting,
      location: const GeoPoint(-18.8792, 47.5079),
      createdAt: DateTime(2026, 3, 1),
      // Le registre figé contient r1, qui s'est retiré: s'il était compté, la
      // victime afficherait « 2 intervenants » alors qu'un seul se mobilise.
      responderIds: const ['r1', 'r2'],
    );
    final when = DateTime(2026, 3, 1);
    repo = _FakeSosRepository(
      myAlert: alert,
      responses: [
        HelpResponse(
          id: 'a1_r1',
          sosAlertId: 'a1',
          responderId: 'r1',
          responseType: ResponseType.comingInPerson,
          status: HelpResponseStatus.cancelled,
          createdAt: when,
          updatedAt: when,
        ),
        HelpResponse(
          id: 'a1_r2',
          sosAlertId: 'a1',
          responderId: 'r2',
          responseType: ResponseType.comingInPerson,
          status: HelpResponseStatus.enRoute,
          createdAt: when,
          updatedAt: when,
        ),
        HelpResponse(
          id: 'a1_r3',
          sosAlertId: 'a1',
          responderId: 'r3',
          responseType: ResponseType.comingInPerson,
          status: HelpResponseStatus.arrived,
          createdAt: when,
          updatedAt: when,
        ),
      ],
      locations: [
        LocationShare(
          id: 'a1_r2',
          sosAlertId: 'a1',
          userId: 'r2',
          // ~1 km au nord.
          currentLocation: const GeoPoint(-18.8702, 47.5079),
          updatedAt: when,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_GuestAuthRepository()),
          sosRepositoryProvider.overrideWithValue(repo),
          sendSosUseCaseProvider.overrideWithValue(_FakeSendSosUseCase(repo)),
        ],
        child: const MaterialApp(home: SosPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Deux intervenants actifs, pas trois: celui qui s'est retiré est exclu.
    expect(find.text('2 intervenants'), findsOneWidget);
    expect(find.text('En route'), findsOneWidget);
    expect(find.text('Arrivé sur place'), findsOneWidget);
    expect(find.text('A proposé son aide'), findsNothing);

    // Distance calculée, pas inventée.
    expect(find.text('1.0 km'), findsOneWidget);
    // r3 n'a pas encore publié de position: on ne fabrique pas de distance.
    expect(find.text('position inconnue'), findsOneWidget);
  });

  testWidgets('la victime distingue une position figée d\'un point en direct', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final alert = SOSAlert(
      id: 'a1',
      userId: 'victim',
      distressType: DistressType.other,
      status: SOSStatus.waiting,
      location: const GeoPoint(-18.8792, 47.5079),
      createdAt: DateTime(2026, 3, 1),
      responderIds: const ['live', 'frozen'],
    );
    final when = DateTime(2026, 3, 1);
    repo = _FakeSosRepository(
      myAlert: alert,
      responses: [
        HelpResponse(
          id: 'a1_live',
          sosAlertId: 'a1',
          responderId: 'live',
          responseType: ResponseType.comingInPerson,
          status: HelpResponseStatus.enRoute,
          createdAt: when,
          updatedAt: when,
        ),
        HelpResponse(
          id: 'a1_frozen',
          sosAlertId: 'a1',
          responderId: 'frozen',
          responseType: ResponseType.comingInPerson,
          status: HelpResponseStatus.enRoute,
          createdAt: when,
          updatedAt: when,
        ),
      ],
      locations: [
        LocationShare(
          id: 'a1_live',
          sosAlertId: 'a1',
          userId: 'live',
          currentLocation: const GeoPoint(-18.8702, 47.5079),
          updatedAt: when,
        ),
        LocationShare(
          id: 'a1_frozen',
          sosAlertId: 'a1',
          userId: 'frozen',
          // ~2 km au nord, GPS coupé: le point reste affiché mais n'est plus
          // un point en direct.
          currentLocation: const GeoPoint(-18.8612, 47.5079),
          isActive: false,
          updatedAt: when,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_GuestAuthRepository()),
          sosRepositoryProvider.overrideWithValue(repo),
          sendSosUseCaseProvider.overrideWithValue(_FakeSendSosUseCase(repo)),
        ],
        child: const MaterialApp(home: SosPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Le point vif s'affiche nu. Le point figé porte la mention, sinon la
    // victime lit « 2.0 km » pour quelqu'un dont le GPS est coupé depuis
    // longtemps.
    expect(find.text('1.0 km'), findsOneWidget);
    expect(find.text('2.0 km'), findsNothing);
    expect(find.text('2.0 km (position figée)'), findsOneWidget);
  });

  testWidgets('l\'invitation à se connecter est visible et cliquable', (
    tester,
  ) async {
    await pumpGuest(tester);

    expect(find.text('Connectez-vous pour envoyer un SOS'), findsOneWidget);
    // Un invited doit comprendre pourquoi l'envoi est bloqué sans que ça
    // ressemble à un échec.
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
