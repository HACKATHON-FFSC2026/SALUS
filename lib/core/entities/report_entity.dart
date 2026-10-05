import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/utils/firestore_converters.dart';

part 'report_entity.freezed.dart';
part 'report_entity.g.dart';

enum ReportTargetType { shelter, zone, road, other }

enum ReportReason { unsafe, unavailable, blocked, other }

enum ReportStatus { open, reviewed, resolved }

@freezed
abstract class Report with _$Report {
  const factory Report({
    required String id,
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? description,
    @GeoPointConverter() GeoPoint? targetLocation,
    @Default(ReportStatus.open) ReportStatus status,
    String? reviewedBy,
    @TimestampConverter() required DateTime createdAt,
  }) = _Report;

  factory Report.fromJson(Map<String, Object?> json) => _$ReportFromJson(json);
}
