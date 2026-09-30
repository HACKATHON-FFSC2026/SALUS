import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/utils/firestore_converters.dart';
import 'package:salus/core/utils/log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const usersCollection = 'users';

/// Full document written the first time a user signs in.
///
/// Built from the [User] entity so the shape can never drift from the
/// serialization tested in `test/user_registration_test.dart`. Every
/// `required` DateTime must be present, otherwise a later `User.fromJson`
/// throws on `json['createdAt'] as Timestamp`.
Map<String, Object?> buildRegistrationData({
  required String uid,
  required String? email,
  required String? displayName,
  required DateTime now,
}) {
  return User(
    id: uid,
    // Google leaves both null for accounts without a profile name / address.
    displayName: _clean(displayName) ?? _emailLocalPart(email) ?? 'Utilisateur',
    email: _clean(email) ?? '',
    authProvider: AuthProvider.google,
    roles: const [UserRole.citizen],
    safetyStatusUpdatedAt: now,
    lastActiveAt: now,
    createdAt: now,
  ).toJson();
}

/// Fields refreshed on every sign-in.
///
/// Deliberately a subset: `roles`, `organizationId`, `isActive` and
/// `createdAt` are set by onboarding/admin and must survive a re-login.
Map<String, Object?> buildSignInRefreshData({
  required String? email,
  required String? displayName,
  required DateTime now,
}) {
  return <String, Object?>{
    'displayName':
        _clean(displayName) ?? _emailLocalPart(email) ?? 'Utilisateur',
    'email': _clean(email) ?? '',
    // Timestamp, not a raw DateTime: cloud_firestore only serializes
    // Timestamp/GeoPoint/primitives and throws on anything else.
    'lastActiveAt': const TimestampConverter().toJson(now),
  };
}

/// Creates the Firestore profile, or refreshes it if it already exists.
///
/// Throws on failure — the caller decides how fatal that is. Firestore
/// buffers the write locally when offline, so the document lands as soon as
/// connectivity returns.
Future<void> ensureUserDocument({
  required String uid,
  required String? email,
  required String? displayName,
}) async {
  final now = DateTime.now();
  final ref = FirebaseFirestore.instance.doc('$usersCollection/$uid');
  final existing = await ref.get();

  if (existing.exists) {
    await ref.set(
      buildSignInRefreshData(email: email, displayName: displayName, now: now),
      SetOptions(merge: true),
    );
  } else {
    await ref.set(
      buildRegistrationData(
        uid: uid,
        email: email,
        displayName: displayName,
        now: now,
      ),
      SetOptions(merge: true),
    );
  }
  Log.info('Profil Firestore à jour pour $uid');
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

String? _emailLocalPart(String? email) {
  final clean = _clean(email);
  if (clean == null || !clean.contains('@')) return null;
  final local = clean.split('@').first.trim();
  return local.isEmpty ? null : local;
}
