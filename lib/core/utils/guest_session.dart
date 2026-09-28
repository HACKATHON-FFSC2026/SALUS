import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ponytail: secure_storage is just the already-installed dep. Switch to
// shared_preferences if more than a couple of plain flags get cached.
const _guestKey = 'salus_guest_mode';
const _storage = FlutterSecureStorage();

Future<bool> isGuestMode() async =>
    await _storage.read(key: _guestKey) == 'true';

Future<void> setGuestMode() => _storage.write(key: _guestKey, value: 'true');
