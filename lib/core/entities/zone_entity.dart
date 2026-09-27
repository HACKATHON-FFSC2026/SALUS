import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/utils/firestore_converters.dart';

part 'zone_entity.freezed.dart';
part 'zone_entity.g.dart';

enum ZoneType { risk, safe }

enum DisasterType {
  earthquake,
  tsunami,
  cyclone,
  flood,
  landslide,
  volcano,
  other,
}

enum Severity { low, medium, high, critical }

enum ZoneOrigin { automatic, manual }

@freezed
abstract class Zone with _$Zone {
  const factory Zone({
    required String id,
    required ZoneType type,
    DisasterType? disasterType,
    @GeoPointListConverter() @Default([]) List<GeoPoint> geometry,
    Severity? severity,
    required ZoneOrigin origin,
    required String source,
    String? createdBy,
    String? organizationId,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime startedAt,
    @TimestampConverter() DateTime? endedAt,
  }) = _Zone;

  factory Zone.fromJson(Map<String, Object?> json) => _$ZoneFromJson(json);
}
