import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/auth/domain/auth_repository.dart';
import 'package:salus/features/auth/domain/user_profile.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/auth/presentation/state/auth_state.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  String? get currentUserId => googleUser?.uid;

  UserProfile? googleUser;
  bool guestThrows = false;
  bool syncThrows = false;
  int syncCalls = 0;

  @override
  Future<UserProfile?> signInWithGoogle() async => googleUser;

  @override
  Future<void> syncProfile(UserProfile profile) async {
    syncCalls++;
    if (syncThrows) throw Exception('firestore indisponible');
  }

  @override
  Future<void> continueAsGuest() async {
    if (guestThrows) throw Exception('secure storage indisponible');
  }

  @override
  Future<bool> hasAccount() async => googleUser != null;
}

const _aina = UserProfile(
  uid: 'u1',
  email: 'aina@example.com',
  displayName: 'Aina',
);

void main() {
  late _FakeAuthRepository fake;
  late ProviderContainer container;

  AuthState state() => container.read(authProvider);

  setUp(() {
    fake = _FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
  });

  tearDown(() => container.dispose());

  test('starts idle', () {
    expect(state().status, AuthStatus.idle);
    expect(state().isAuthenticated, isFalse);
  });

  group('signInWithGoogle', () {
    test('authenticates and syncs the profile', () async {
      fake.googleUser = _aina;

      await container.read(authProvider.notifier).signInWithGoogle();

      expect(state().status, AuthStatus.authenticated);
      expect(state().user, _aina);
      expect(fake.syncCalls, 1);
      expect(state().warningMessage, isNull);
      expect(state().errorMessage, isNull);
    });

    test('a rejected sign-in keeps the user on the page', () async {
      fake.googleUser = null;

      await container.read(authProvider.notifier).signInWithGoogle();

      expect(state().status, AuthStatus.failure);
      expect(state().isAuthenticated, isFalse);
      expect(state().errorMessage, isNotNull);
      expect(fake.syncCalls, 0, reason: 'rien à synchroniser sans compte');
    });

    test('a Firestore failure is a warning, not a block', () async {
      // App d'urgence: l'utilisateur doit atteindre le SOS même hors ligne.
      fake.googleUser = _aina;
      fake.syncThrows = true;

      await container.read(authProvider.notifier).signInWithGoogle();

      expect(state().status, AuthStatus.authenticated);
      expect(state().isAuthenticated, isTrue);
      expect(state().warningMessage, isNotNull);
      expect(state().errorMessage, isNull);
    });
  });

  group('continueAsGuest', () {
    test('authenticates without a profile write', () async {
      await container.read(authProvider.notifier).continueAsGuest();

      expect(state().status, AuthStatus.authenticated);
      expect(state().user, isNull);
      expect(fake.syncCalls, 0);
    });

    test('reports a storage failure instead of entering', () async {
      fake.guestThrows = true;

      await container.read(authProvider.notifier).continueAsGuest();

      expect(state().status, AuthStatus.failure);
      expect(state().isAuthenticated, isFalse);
    });
  });

  test('isBusy covers both the network and the Firestore phase', () async {
    fake.googleUser = _aina;
    final statuses = <AuthStatus>[];
    container.listen(authProvider, (_, next) => statuses.add(next.status));

    await container.read(authProvider.notifier).signInWithGoogle();

    expect(statuses, [
      AuthStatus.busy,
      AuthStatus.registering,
      AuthStatus.authenticated,
    ]);
  });
}
