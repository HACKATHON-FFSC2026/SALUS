// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Organization _$OrganizationFromJson(Map<String, dynamic> json) =>
    _Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$OrganizationTypeEnumMap, json['type']),
      verified: json['verified'] as bool? ?? false,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: _$JsonConverterFromJson<Timestamp, DateTime>(
        json['verifiedAt'],
        const TimestampConverter().fromJson,
      ),
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String,
      createdAt: const TimestampConverter().fromJson(
        json['createdAt'] as Timestamp,
      ),
    );

Map<String, dynamic> _$OrganizationToJson(_Organization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$OrganizationTypeEnumMap[instance.type]!,
      'verified': instance.verified,
      'verifiedBy': instance.verifiedBy,
      'verifiedAt': _$JsonConverterToJson<Timestamp, DateTime>(
        instance.verifiedAt,
        const TimestampConverter().toJson,
      ),
      'contactEmail': instance.contactEmail,
      'contactPhone': instance.contactPhone,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$OrganizationTypeEnumMap = {
  OrganizationType.ngo: 'ngo',
  OrganizationType.government: 'government',
  OrganizationType.emergencyServices: 'emergencyServices',
  OrganizationType.other: 'other',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
