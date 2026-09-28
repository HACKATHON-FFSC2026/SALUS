import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:salus/core/utils/log.dart';

// ponytail: secure_storage is just the already-installed dep. Switch to
// shared_preferences if more than a couple of plain flags get cached.
const _guestKey = 'salus_guest_mode';
const _storage = FlutterSecureStorage();

Future<void> setGuestMode() => _storage.write(key: _guestKey, value: 'true');

/// True when the app can go straight to the main tabs.
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
