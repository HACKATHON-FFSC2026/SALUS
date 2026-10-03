// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Zone _$ZoneFromJson(Map<String, dynamic> json) => _Zone(
  id: json['id'] as String,
  type: $enumDecode(_$ZoneTypeEnumMap, json['type']),
  disasterType: $enumDecodeNullable(
    _$DisasterTypeEnumMap,
    json['disasterType'],
  ),
  geometry: json['geometry'] == null
      ? const []
      : const GeoPointListConverter().fromJson(json['geometry'] as List),
  severity: $enumDecodeNullable(_$SeverityEnumMap, json['severity']),
  origin: $enumDecode(_$ZoneOriginEnumMap, json['origin']),
  source: json['source'] as String,
  description: json['description'] as String?,
  createdBy: json['createdBy'] as String?,
  organizationId: json['organizationId'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  startedAt: const TimestampConverter().fromJson(
    json['startedAt'] as Timestamp,
  ),
  endedAt: _$JsonConverterFromJson<Timestamp, DateTime>(
    json['endedAt'],
    const TimestampConverter().fromJson,
  ),
);

Map<String, dynamic> _$ZoneToJson(_Zone instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$ZoneTypeEnumMap[instance.type]!,
  'disasterType': _$DisasterTypeEnumMap[instance.disasterType],
  'geometry': const GeoPointListConverter().toJson(instance.geometry),
  'severity': _$SeverityEnumMap[instance.severity],
  'origin': _$ZoneOriginEnumMap[instance.origin]!,
  'source': instance.source,
  'description': instance.description,
  'createdBy': instance.createdBy,
  'organizationId': instance.organizationId,
  'isActive': instance.isActive,
  'startedAt': const TimestampConverter().toJson(instance.startedAt),
  'endedAt': _$JsonConverterToJson<Timestamp, DateTime>(
    instance.endedAt,
    const TimestampConverter().toJson,
  ),
};

const _$ZoneTypeEnumMap = {ZoneType.risk: 'risk', ZoneType.safe: 'safe'};

const _$DisasterTypeEnumMap = {
  DisasterType.earthquake: 'earthquake',
  DisasterType.tsunami: 'tsunami',
  DisasterType.cyclone: 'cyclone',
  DisasterType.flood: 'flood',
  DisasterType.landslide: 'landslide',
  DisasterType.volcano: 'volcano',
  DisasterType.other: 'other',
};

const _$SeverityEnumMap = {
  Severity.low: 'low',
  Severity.medium: 'medium',
  Severity.high: 'high',
  Severity.critical: 'critical',
};

const _$ZoneOriginEnumMap = {
  ZoneOrigin.automatic: 'automatic',
  ZoneOrigin.manual: 'manual',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
