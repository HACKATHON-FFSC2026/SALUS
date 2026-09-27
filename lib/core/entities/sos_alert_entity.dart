import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/utils/firestore_converters.dart';

part 'sos_alert_entity.freezed.dart';
part 'sos_alert_entity.g.dart';

enum DistressType { medical, trapped, evacuation, other }

enum SOSStatus { waiting, inProgress, resolved, cancelled }

@freezed
abstract class SOSAlert with _$SOSAlert {
  const factory SOSAlert({
    required String id,
    required String userId,
    @GeoPointConverter() required GeoPoint location,
    required DistressType distressType,
    String? description,
    @Default(SOSStatus.waiting) SOSStatus status,
    @Default(0) int respondersCount,
    String? assignedOrganizationId,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? resolvedAt,
  }) = _SOSAlert;

  factory SOSAlert.fromJson(Map<String, Object?> json) =>
      _$SOSAlertFromJson(json);
}
