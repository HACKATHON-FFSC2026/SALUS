import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/auth/data/user_registration.dart';

void main() {
  final now = DateTime(2026, 9, 29, 10, 30);

  group('buildRegistrationData', () {
    test('produces a document User.fromJson can read back', () {
      final data = buildRegistrationData(
        uid: 'u1',
        email: 'aina@example.com',
        displayName: 'Aina',
        now: now,
      );

      final user = User.fromJson(data);
      expect(user.id, 'u1');
      expect(user.roles, const [UserRole.citizen]);
      expect(user.createdAt, now);
      expect(user.lastActiveAt, now);
      expect(user.safetyStatusUpdatedAt, now);
      expect(user.safetyStatus, SafetyStatus.unknown);
    });

    test('falls back when Google gives no display name', () {
      final data = buildRegistrationData(
        uid: 'u2',
        email: 'rabe@example.com',
        displayName: null,
        now: now,
      );
      expect(data['displayName'], 'rabe');
      expect(User.fromJson(data).displayName, 'rabe');
    });

    test('survives an account with neither name nor email', () {
      final data = buildRegistrationData(
        uid: 'u3',
        email: null,
        displayName: '   ',
        now: now,
      );
      expect(data['displayName'], 'Utilisateur');
      expect(data['email'], '');
      expect(User.fromJson(data).id, 'u3');
    });
  });

  group('buildSignInRefreshData', () {
    test('never touches roles, organizationId, isActive or createdAt', () {
      final data = buildSignInRefreshData(
        email: 'aina@example.com',
        displayName: 'Aina R.',
        now: now,
      );

      // A full-entity write here would reset roles/createdAt on every login.
      expect(data.keys, {'displayName', 'email', 'lastActiveAt'});
      expect(data['lastActiveAt'], isA<Timestamp>());
      expect(data['displayName'], 'Aina R.');
    });

    test('is a valid merge payload over an existing document', () {
      final created = buildRegistrationData(
        uid: 'u4',
        email: 'aina@example.com',
        displayName: 'Aina',
        now: DateTime(2026, 1, 1),
      );
      final merged = <String, Object?>{
        ...created,
        ...buildSignInRefreshData(
          email: 'aina@example.com',
          displayName: 'Aina R.',
          now: now,
        ),
      };

      final user = User.fromJson(merged);
      expect(user.createdAt, DateTime(2026, 1, 1), reason: 'createdAt pinné');
      expect(user.lastActiveAt, now);
      expect(user.roles, const [UserRole.citizen]);
    });
  });

  test('every required DateTime is written as a Timestamp', () {
    final data = buildRegistrationData(
      uid: 'u5',
      email: 'a@b.com',
      displayName: 'A',
      now: now,
    );
    for (final key in const [
      'safetyStatusUpdatedAt',
      'lastActiveAt',
      'createdAt',
    ]) {
      expect(data[key], isA<Timestamp>(), reason: '$key manquant');
    }
  });
}
