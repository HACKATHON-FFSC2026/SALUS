import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/utils/firestore_converters.dart';

part 'location_share_entity.freezed.dart';
part 'location_share_entity.g.dart';

@freezed
abstract class LocationShare with _$LocationShare {
  const factory LocationShare({
    required String id,
    required String sosAlertId,
    required String userId,
    @GeoPointConverter() required GeoPoint currentLocation,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime updatedAt,
  }) = _LocationShare;

  factory LocationShare.fromJson(Map<String, Object?> json) =>
      _$LocationShareFromJson(json);
}
