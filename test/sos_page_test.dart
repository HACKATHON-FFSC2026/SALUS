import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/auth/domain/auth_repository.dart';
import 'package:salus/features/auth/domain/user_profile.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/sos/data/repositories/sos_repository_impl.dart';
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
      Stream.value(List<SOSAlert>.empty());
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