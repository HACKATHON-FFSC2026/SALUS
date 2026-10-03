import 'package:salus/features/auth/domain/user_profile.dart';

/// Port du domaine. Les pages ne connaissent que ce contrat — jamais
/// FirebaseAuth, GoogleSignIn ni Firestore. Implémentation dans
/// features/auth/data.
abstract class AuthRepository {
  /// Identifiant Firebase de l'utilisateur connecté, null en mode invité.
  String? get currentUserId;

  /// Profil de la session déjà ouverte, null si aucun compte Firebase.
  ///
  /// Synchrone à dessein : Firebase restaure sa session sur disque avant le
  /// premier frame, l'état applicatif doit donc pouvoir se réhydrater sans
  /// attente. `null` pour un invité, qui n'a pas de compte Firebase.
  UserProfile? get currentProfile;

  /// null si l'authentification Google a échoué (refus, réseau, compte nul).
  Future<UserProfile?> signInWithGoogle();

  /// Écrit ou rafraîchit le profil distant. Throw si l'écriture échoue :
  /// l'appelant décide si c'est bloquant ou non.
  Future<void> syncProfile(UserProfile profile);

  /// Ouvre l'app sans compte, pour les cas d'urgence.
  Future<void> continueAsGuest();

  /// true si l'app peut aller directement aux onglets.
  Future<bool> hasAccount();

  /// Termine la session distante.
  Future<void> signOut();
}
