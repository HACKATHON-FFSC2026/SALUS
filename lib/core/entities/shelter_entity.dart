import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/utils/firestore_converters.dart';

part 'shelter_entity.freezed.dart';
part 'shelter_entity.g.dart';

enum ShelterStatus { open, almostFull, full, closed }

enum ValidationStatus { pending, validated, rejected }

// ponytail: évite explicitToJson sur le parent. Généraliser si 2e cas apparaît.
class ShelterResourcesConverter
    implements JsonConverter<ShelterResources, Map<String, Object?>> {
  const ShelterResourcesConverter();

  @override
  ShelterResources fromJson(Map<String, Object?> json) =>
      ShelterResources.fromJson(json);

  @override
  Map<String, Object?> toJson(ShelterResources object) => object.toJson();
}

@freezed
abstract class ShelterResources with _$ShelterResources {
  const factory ShelterResources({
    @Default(false) bool water,
    @Default(false) bool food,
    @Default(false) bool electricity,
    @Default(false) bool medicalKit,
  }) = _ShelterResources;

  factory ShelterResources.fromJson(Map<String, Object?> json) =>
      _$ShelterResourcesFromJson(json);
}

@freezed
abstract class Shelter with _$Shelter {
  const factory Shelter({
    required String id,
    required String name,
    @GeoPointConverter() required GeoPoint location,
    required String address,
    required int capacityTotal,
    @Default(0) int capacityOccupied,
    required ShelterStatus status,
    @ShelterResourcesConverter() required ShelterResources resources,
    @Default([]) List<String> photos,
    required String createdBy,
    String? managedBy,
    String? organizationId,
    @Default(ValidationStatus.pending) ValidationStatus validationStatus,
    String? validatedBy,
    @Default(0) int unsafeReportsCount,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _Shelter;

  factory Shelter.fromJson(Map<String, Object?> json) =>
      _$ShelterFromJson(json);
}
