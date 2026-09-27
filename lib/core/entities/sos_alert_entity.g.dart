// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_alert_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SOSAlert _$SOSAlertFromJson(Map<String, dynamic> json) => _SOSAlert(
  id: json['id'] as String,
  userId: json['userId'] as String,
  location: const GeoPointConverter().fromJson(json['location'] as GeoPoint),
  distressType: $enumDecode(_$DistressTypeEnumMap, json['distressType']),
  description: json['description'] as String?,
  status:
      $enumDecodeNullable(_$SOSStatusEnumMap, json['status']) ??
      SOSStatus.waiting,
  respondersCount: (json['respondersCount'] as num?)?.toInt() ?? 0,
  assignedOrganizationId: json['assignedOrganizationId'] as String?,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  resolvedAt: _$JsonConverterFromJson<Timestamp, DateTime>(
    json['resolvedAt'],
    const TimestampConverter().fromJson,
  ),
);

Map<String, dynamic> _$SOSAlertToJson(_SOSAlert instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'location': const GeoPointConverter().toJson(instance.location),
  'distressType': _$DistressTypeEnumMap[instance.distressType]!,
  'description': instance.description,
  'status': _$SOSStatusEnumMap[instance.status]!,
  'respondersCount': instance.respondersCount,
  'assignedOrganizationId': instance.assignedOrganizationId,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'resolvedAt': _$JsonConverterToJson<Timestamp, DateTime>(
    instance.resolvedAt,
    const TimestampConverter().toJson,
  ),
};

const _$DistressTypeEnumMap = {
  DistressType.medical: 'medical',
  DistressType.trapped: 'trapped',
  DistressType.evacuation: 'evacuation',
  DistressType.other: 'other',
};

const _$SOSStatusEnumMap = {
  SOSStatus.waiting: 'waiting',
  SOSStatus.inProgress: 'inProgress',
  SOSStatus.resolved: 'resolved',
  SOSStatus.cancelled: 'cancelled',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
