// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_share_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocationShare _$LocationShareFromJson(Map<String, dynamic> json) =>
    _LocationShare(
      id: json['id'] as String,
      sosAlertId: json['sosAlertId'] as String,
      userId: json['userId'] as String,
      currentLocation: const GeoPointConverter().fromJson(
        json['currentLocation'] as GeoPoint,
      ),
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: const TimestampConverter().fromJson(
        json['updatedAt'] as Timestamp,
      ),
    );

Map<String, dynamic> _$LocationShareToJson(
  _LocationShare instance,
) => <String, dynamic>{
  'id': instance.id,
  'sosAlertId': instance.sosAlertId,
  'userId': instance.userId,
  'currentLocation': const GeoPointConverter().toJson(instance.currentLocation),
  'isActive': instance.isActive,
  'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
};
