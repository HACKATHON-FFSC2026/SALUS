import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/utils/firestore_converters.dart';

part 'organization_entity.freezed.dart';
part 'organization_entity.g.dart';

enum OrganizationType { ngo, government, emergencyServices, other }

@freezed
abstract class Organization with _$Organization {
  const factory Organization({
    required String id,
    required String name,
    required OrganizationType type,
    @Default(false) bool verified,
    String? verifiedBy,
    @TimestampConverter() DateTime? verifiedAt,
    required String contactEmail,
    required String contactPhone,
    @TimestampConverter() required DateTime createdAt,
  }) = _Organization;

  factory Organization.fromJson(Map<String, Object?> json) =>
      _$OrganizationFromJson(json);
}
