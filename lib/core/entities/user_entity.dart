import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/utils/firestore_converters.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

enum AuthProvider { google, apple }

enum UserRole { citizen, shelterManager, organizationMember, admin }

enum CompetencyTag { firstAidTrained, healthProfessional }

enum SafetyStatus { safe, inDistress, unknown }

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String displayName,
    required String email,
    String? phoneNumber,
    required AuthProvider authProvider,
    @Default([]) List<UserRole> roles,
    String? organizationId,
    CompetencyTag? competencyTag,
    @Default(SafetyStatus.unknown) SafetyStatus safetyStatus,
    @TimestampConverter() required DateTime safetyStatusUpdatedAt,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime lastActiveAt,
    @TimestampConverter() required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
