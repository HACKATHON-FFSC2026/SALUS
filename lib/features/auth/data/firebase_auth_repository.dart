import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/auth/data/user_registration.dart';
import 'package:salus/features/auth/domain/auth_repository.dart';
import 'package:salus/features/auth/domain/user_profile.dart';

// ponytail: secure_storage is just the already-installed dep. Switch to
// shared_preferences if more than a couple of plain flags get cached.
const _guestKey = 'salus_guest_mode';
const _storage = FlutterSecureStorage();

/// Adaptateur Firebase du port [AuthRepository]. Seul endroit du projet
/// autorisé à parler FirebaseAuth / GoogleSignIn / Firestore.
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  @override
  Future<UserProfile?> signInWithGoogle() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final credential = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: account.authentication.idToken),
      );
      final user = credential.user;
      if (user == null) return null;
      return UserProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
    } catch (e, s) {
      Log.error('Connexion Google impossible', e, s);
      return null;
    }
  }

  @override
  Future<void> syncProfile(UserProfile profile) => ensureUserDocument(
    uid: profile.uid,
    email: profile.email,
    displayName: profile.displayName,
  );

  @override
  Future<void> continueAsGuest() =>
      _storage.write(key: _guestKey, value: 'true');

  /// True when the app can go straight to the main tabs.
  @override
  Future<bool> hasAccount() async {
    if (await _storage.read(key: _guestKey) == 'true') return true;
    // ponytail: Firebase can be unconfigured on some platforms, which throws
    // here. Treat it as "not signed in" — re-run `flutterfire configure` instead.
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      Log.warning('FirebaseAuth indisponible: $e');
      return false;
    }
  }
}
