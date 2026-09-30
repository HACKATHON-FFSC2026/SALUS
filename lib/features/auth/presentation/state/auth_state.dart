import 'package:salus/features/auth/domain/user_profile.dart';

enum AuthStatus { idle, busy, registering, authenticated, failure }

class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.errorMessage,
    this.warningMessage,
  });

  final AuthStatus status;
  final UserProfile? user;

  /// Échec bloquant: l'utilisateur reste sur la page de connexion.
  final String? errorMessage;

  /// Échec non bloquant: l'utilisateur entre quand même dans l'app.
  final String? warningMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isBusy =>
      status == AuthStatus.busy || status == AuthStatus.registering;
  bool get isRegistering => status == AuthStatus.registering;
}
