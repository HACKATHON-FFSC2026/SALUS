import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/features/auth/data/firebase_auth_repository.dart';
import 'package:salus/features/auth/domain/auth_repository.dart';
import 'package:salus/features/auth/presentation/state/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const FirebaseAuthRepository(),
);

/// Décision du splash. Le délai laisse le logo s'afficher avant de trancher.
final hasAccountProvider = FutureProvider<bool>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
  return ref.watch(authRepositoryProvider).hasAccount();
});

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// uid Firebase de l'utilisateur connecté, `null` s'il est invité.
///
/// Les features qui écrivent dans Firestore sous l'identité de l'utilisateur
/// (SOS, signalements) le lisent ici plutôt que d'instancier leur propre
/// FirebaseAuth.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.uid;
});

/// Règles de connexion. La page ne fait que refléter l'état.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Firebase restaure sa session sur disque avant le premier frame. Sans cette
    // réhydratation, relancer l'app rebasculait en « non connecté » alors que
    // l'utilisateur ne s'était jamais déconnecté : la page SOS lui redemandait
    // de se connecter et masquait le bouton d'envoi.
    final user = ref.read(authRepositoryProvider).currentProfile;
    if (user == null) return const AuthState();
    return AuthState(status: AuthStatus.authenticated, user: user);
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Un échec Firestore n'est volontairement pas bloquant: app d'urgence,
  /// l'utilisateur doit atteindre le bouton SOS même sans réseau. Firestore
  /// rejoue l'écriture à la prochaine synchronisation.
  Future<void> signInWithGoogle() async {
    state = const AuthState(status: AuthStatus.busy);
    final user = await _repository.signInWithGoogle();
    if (user == null) {
      state = const AuthState(
        status: AuthStatus.failure,
        errorMessage: 'Connexion Google impossible',
      );
      return;
    }

    state = const AuthState(status: AuthStatus.registering);
    String? warning;
    try {
      await _repository.syncProfile(user);
    } catch (e) {
      warning = 'Profil non synchronisé, réessaie plus tard';
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      warningMessage: warning,
    );
  }

  Future<void> continueAsGuest() async {
    state = const AuthState(status: AuthStatus.busy);
    try {
      await _repository.continueAsGuest();
      state = const AuthState(status: AuthStatus.authenticated);
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.failure,
        errorMessage: 'Mode hors connexion indisponible',
      );
    }
  }
}
