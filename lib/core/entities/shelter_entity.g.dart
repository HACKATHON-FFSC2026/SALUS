// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelter_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShelterResources _$ShelterResourcesFromJson(Map<String, dynamic> json) =>
    _ShelterResources(
      water: json['water'] as bool? ?? false,
      food: json['food'] as bool? ?? false,
      electricity: json['electricity'] as bool? ?? false,
      medicalKit: json['medicalKit'] as bool? ?? false,
    );

Map<String, dynamic> _$ShelterResourcesToJson(_ShelterResources instance) =>
    <String, dynamic>{
      'water': instance.water,
      'food': instance.food,
      'electricity': instance.electricity,
      'medicalKit': instance.medicalKit,
    };

_Shelter _$ShelterFromJson(Map<String, dynamic> json) => _Shelter(
  id: json['id'] as String,
  name: json['name'] as String,
  location: const GeoPointConverter().fromJson(json['location'] as GeoPoint),
  address: json['address'] as String,
  capacityTotal: (json['capacityTotal'] as num).toInt(),
  capacityOccupied: (json['capacityOccupied'] as num?)?.toInt() ?? 0,
  status: $enumDecode(_$ShelterStatusEnumMap, json['status']),
  resources: const ShelterResourcesConverter().fromJson(
    json['resources'] as Map<String, Object?>,
  ),
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdBy: json['createdBy'] as String,
  managedBy: json['managedBy'] as String?,
  organizationId: json['organizationId'] as String?,
  validationStatus:
      $enumDecodeNullable(
        _$ValidationStatusEnumMap,
        json['validationStatus'],
      ) ??
      ValidationStatus.pending,
  validatedBy: json['validatedBy'] as String?,
  unsafeReportsCount: (json['unsafeReportsCount'] as num?)?.toInt() ?? 0,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  updatedAt: const TimestampConverter().fromJson(
    json['updatedAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$ShelterToJson(_Shelter instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'location': const GeoPointConverter().toJson(instance.location),
  'address': instance.address,
  'capacityTotal': instance.capacityTotal,
  'capacityOccupied': instance.capacityOccupied,
  'status': _$ShelterStatusEnumMap[instance.status]!,
  'resources': const ShelterResourcesConverter().toJson(instance.resources),
  'photos': instance.photos,
  'createdBy': instance.createdBy,
  'managedBy': instance.managedBy,
  'organizationId': instance.organizationId,
  'validationStatus': _$ValidationStatusEnumMap[instance.validationStatus]!,
  'validatedBy': instance.validatedBy,
  'unsafeReportsCount': instance.unsafeReportsCount,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
};

const _$ShelterStatusEnumMap = {
  ShelterStatus.open: 'open',
  ShelterStatus.almostFull: 'almostFull',
  ShelterStatus.full: 'full',
  ShelterStatus.closed: 'closed',
};

const _$ValidationStatusEnumMap = {
  ValidationStatus.pending: 'pending',
  ValidationStatus.validated: 'validated',
  ValidationStatus.rejected: 'rejected',
};
