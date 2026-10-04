// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Report _$ReportFromJson(Map<String, dynamic> json) => _Report(
  id: json['id'] as String,
  reporterId: json['reporterId'] as String,
  targetType: $enumDecode(_$ReportTargetTypeEnumMap, json['targetType']),
  targetId: json['targetId'] as String,
  reason: $enumDecode(_$ReportReasonEnumMap, json['reason']),
  description: json['description'] as String?,
  targetLocation: _$JsonConverterFromJson<GeoPoint, GeoPoint>(
    json['targetLocation'],
    const GeoPointConverter().fromJson,
  ),
  status:
      $enumDecodeNullable(_$ReportStatusEnumMap, json['status']) ??
      ReportStatus.open,
  reviewedBy: json['reviewedBy'] as String?,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$ReportToJson(_Report instance) => <String, dynamic>{
  'id': instance.id,
  'reporterId': instance.reporterId,
  'targetType': _$ReportTargetTypeEnumMap[instance.targetType]!,
  'targetId': instance.targetId,
  'reason': _$ReportReasonEnumMap[instance.reason]!,
  'description': instance.description,
  'targetLocation': _$JsonConverterToJson<GeoPoint, GeoPoint>(
    instance.targetLocation,
    const GeoPointConverter().toJson,
  ),
  'status': _$ReportStatusEnumMap[instance.status]!,
  'reviewedBy': instance.reviewedBy,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};

const _$ReportTargetTypeEnumMap = {
  ReportTargetType.shelter: 'shelter',
  ReportTargetType.zone: 'zone',
  ReportTargetType.road: 'road',
  ReportTargetType.other: 'other',
};

const _$ReportReasonEnumMap = {
  ReportReason.unsafe: 'unsafe',
  ReportReason.unavailable: 'unavailable',
  ReportReason.blocked: 'blocked',
  ReportReason.other: 'other',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$ReportStatusEnumMap = {
  ReportStatus.open: 'open',
  ReportStatus.reviewed: 'reviewed',
  ReportStatus.resolved: 'resolved',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
