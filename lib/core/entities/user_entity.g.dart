// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String?,
  authProvider: $enumDecode(_$AuthProviderEnumMap, json['authProvider']),
  roles:
      (json['roles'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$UserRoleEnumMap, e))
          .toList() ??
      const [],
  organizationId: json['organizationId'] as String?,
  competencyTag: $enumDecodeNullable(
    _$CompetencyTagEnumMap,
    json['competencyTag'],
  ),
  safetyStatus:
      $enumDecodeNullable(_$SafetyStatusEnumMap, json['safetyStatus']) ??
      SafetyStatus.unknown,
  safetyStatusUpdatedAt: const TimestampConverter().fromJson(
    json['safetyStatusUpdatedAt'] as Timestamp,
  ),
  isActive: json['isActive'] as bool? ?? true,
  lastActiveAt: const TimestampConverter().fromJson(
    json['lastActiveAt'] as Timestamp,
  ),
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'authProvider': _$AuthProviderEnumMap[instance.authProvider]!,
  'roles': instance.roles.map((e) => _$UserRoleEnumMap[e]!).toList(),
  'organizationId': instance.organizationId,
  'competencyTag': _$CompetencyTagEnumMap[instance.competencyTag],
  'safetyStatus': _$SafetyStatusEnumMap[instance.safetyStatus]!,
  'safetyStatusUpdatedAt': const TimestampConverter().toJson(
    instance.safetyStatusUpdatedAt,
  ),
  'isActive': instance.isActive,
  'lastActiveAt': const TimestampConverter().toJson(instance.lastActiveAt),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};

const _$AuthProviderEnumMap = {
  AuthProvider.google: 'google',
  AuthProvider.apple: 'apple',
};

const _$UserRoleEnumMap = {
  UserRole.citizen: 'citizen',
  UserRole.shelterManager: 'shelterManager',
  UserRole.organizationMember: 'organizationMember',
  UserRole.admin: 'admin',
};

const _$CompetencyTagEnumMap = {
  CompetencyTag.firstAidTrained: 'firstAidTrained',
  CompetencyTag.healthProfessional: 'healthProfessional',
};

const _$SafetyStatusEnumMap = {
  SafetyStatus.safe: 'safe',
  SafetyStatus.inDistress: 'inDistress',
  SafetyStatus.unknown: 'unknown',
};
