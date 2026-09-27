// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shelter_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShelterResources {

 bool get water; bool get food; bool get electricity; bool get medicalKit;
/// Create a copy of ShelterResources
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShelterResourcesCopyWith<ShelterResources> get copyWith => _$ShelterResourcesCopyWithImpl<ShelterResources>(this as ShelterResources, _$identity);

  /// Serializes this ShelterResources to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShelterResources;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShelterResources&&(identical(other.water, _this.water) || other.water == _this.water)&&(identical(other.food, _this.food) || other.food == _this.food)&&(identical(other.electricity, _this.electricity) || other.electricity == _this.electricity)&&(identical(other.medicalKit, _this.medicalKit) || other.medicalKit == _this.medicalKit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShelterResources;
  return Object.hash(runtimeType,_this.water,_this.food,_this.electricity,_this.medicalKit);
}

@override
String toString() {
  final _this = this as ShelterResources;
  return 'ShelterResources(water: ${_this.water}, food: ${_this.food}, electricity: ${_this.electricity}, medicalKit: ${_this.medicalKit})';
}


}

/// @nodoc
abstract mixin class $ShelterResourcesCopyWith<$Res>  {
  factory $ShelterResourcesCopyWith(ShelterResources value, $Res Function(ShelterResources) _then) = _$ShelterResourcesCopyWithImpl;
@useResult
$Res call({
 bool water, bool food, bool electricity, bool medicalKit
});




}
/// @nodoc
class _$ShelterResourcesCopyWithImpl<$Res>
    implements $ShelterResourcesCopyWith<$Res> {
  _$ShelterResourcesCopyWithImpl(this._self, this._then);

  final ShelterResources _self;
  final $Res Function(ShelterResources) _then;

/// Create a copy of ShelterResources
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? water = null,Object? food = null,Object? electricity = null,Object? medicalKit = null,}) {
  return _then(ShelterResources(
water: null == water ? _self.water : water // ignore: cast_nullable_to_non_nullable
as bool,food: null == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as bool,electricity: null == electricity ? _self.electricity : electricity // ignore: cast_nullable_to_non_nullable
as bool,medicalKit: null == medicalKit ? _self.medicalKit : medicalKit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ShelterResources].
extension ShelterResourcesPatterns on ShelterResources {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShelterResources value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShelterResources() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShelterResources value)  $default,){
final _that = this;
switch (_that) {
case _ShelterResources():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShelterResources value)?  $default,){
final _that = this;
switch (_that) {
case _ShelterResources() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool water,  bool food,  bool electricity,  bool medicalKit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShelterResources() when $default != null:
return $default(_that.water,_that.food,_that.electricity,_that.medicalKit);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool water,  bool food,  bool electricity,  bool medicalKit)  $default,) {final _that = this;
switch (_that) {
case _ShelterResources():
return $default(_that.water,_that.food,_that.electricity,_that.medicalKit);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool water,  bool food,  bool electricity,  bool medicalKit)?  $default,) {final _that = this;
switch (_that) {
case _ShelterResources() when $default != null:
return $default(_that.water,_that.food,_that.electricity,_that.medicalKit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShelterResources implements ShelterResources {
  const _ShelterResources({this.water = false, this.food = false, this.electricity = false, this.medicalKit = false});
  factory _ShelterResources.fromJson(Map<String, dynamic> json) => _$ShelterResourcesFromJson(json);

@override@JsonKey() final  bool water;
@override@JsonKey() final  bool food;
@override@JsonKey() final  bool electricity;
@override@JsonKey() final  bool medicalKit;

/// Create a copy of ShelterResources
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShelterResourcesCopyWith<_ShelterResources> get copyWith => __$ShelterResourcesCopyWithImpl<_ShelterResources>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShelterResourcesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShelterResources&&(identical(other.water, water) || other.water == water)&&(identical(other.food, food) || other.food == food)&&(identical(other.electricity, electricity) || other.electricity == electricity)&&(identical(other.medicalKit, medicalKit) || other.medicalKit == medicalKit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,water,food,electricity,medicalKit);
}

@override
String toString() {
    return 'ShelterResources(water: $water, food: $food, electricity: $electricity, medicalKit: $medicalKit)';
}


}

/// @nodoc
abstract mixin class _$ShelterResourcesCopyWith<$Res> implements $ShelterResourcesCopyWith<$Res> {
  factory _$ShelterResourcesCopyWith(_ShelterResources value, $Res Function(_ShelterResources) _then) = __$ShelterResourcesCopyWithImpl;
@override @useResult
$Res call({
 bool water, bool food, bool electricity, bool medicalKit
});




}
/// @nodoc
class __$ShelterResourcesCopyWithImpl<$Res>
    implements _$ShelterResourcesCopyWith<$Res> {
  __$ShelterResourcesCopyWithImpl(this._self, this._then);

  final _ShelterResources _self;
  final $Res Function(_ShelterResources) _then;

/// Create a copy of ShelterResources
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? water = null,Object? food = null,Object? electricity = null,Object? medicalKit = null,}) {
  return _then(_ShelterResources(
water: null == water ? _self.water : water // ignore: cast_nullable_to_non_nullable
as bool,food: null == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as bool,electricity: null == electricity ? _self.electricity : electricity // ignore: cast_nullable_to_non_nullable
as bool,medicalKit: null == medicalKit ? _self.medicalKit : medicalKit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Shelter {

 String get id; String get name;@GeoPointConverter() GeoPoint get location; String get address; int get capacityTotal; int get capacityOccupied; ShelterStatus get status;@ShelterResourcesConverter() ShelterResources get resources; List<String> get photos; String get createdBy; String? get managedBy; String? get organizationId; ValidationStatus get validationStatus; String? get validatedBy; int get unsafeReportsCount;@TimestampConverter() DateTime get createdAt;@TimestampConverter() DateTime get updatedAt;
/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShelterCopyWith<Shelter> get copyWith => _$ShelterCopyWithImpl<Shelter>(this as Shelter, _$identity);

  /// Serializes this Shelter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Shelter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shelter&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.capacityTotal, _this.capacityTotal) || other.capacityTotal == _this.capacityTotal)&&(identical(other.capacityOccupied, _this.capacityOccupied) || other.capacityOccupied == _this.capacityOccupied)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.resources, _this.resources) || other.resources == _this.resources)&&const DeepCollectionEquality().equals(other.photos, _this.photos)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.managedBy, _this.managedBy) || other.managedBy == _this.managedBy)&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.validationStatus, _this.validationStatus) || other.validationStatus == _this.validationStatus)&&(identical(other.validatedBy, _this.validatedBy) || other.validatedBy == _this.validatedBy)&&(identical(other.unsafeReportsCount, _this.unsafeReportsCount) || other.unsafeReportsCount == _this.unsafeReportsCount)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Shelter;
  return Object.hash(runtimeType,_this.id,_this.name,_this.location,_this.address,_this.capacityTotal,_this.capacityOccupied,_this.status,_this.resources,const DeepCollectionEquality().hash(_this.photos),_this.createdBy,_this.managedBy,_this.organizationId,_this.validationStatus,_this.validatedBy,_this.unsafeReportsCount,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Shelter;
  return 'Shelter(id: ${_this.id}, name: ${_this.name}, location: ${_this.location}, address: ${_this.address}, capacityTotal: ${_this.capacityTotal}, capacityOccupied: ${_this.capacityOccupied}, status: ${_this.status}, resources: ${_this.resources}, photos: ${_this.photos}, createdBy: ${_this.createdBy}, managedBy: ${_this.managedBy}, organizationId: ${_this.organizationId}, validationStatus: ${_this.validationStatus}, validatedBy: ${_this.validatedBy}, unsafeReportsCount: ${_this.unsafeReportsCount}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ShelterCopyWith<$Res>  {
  factory $ShelterCopyWith(Shelter value, $Res Function(Shelter) _then) = _$ShelterCopyWithImpl;
@useResult
$Res call({
 String id, String name,@GeoPointConverter() GeoPoint location, String address, int capacityTotal, int capacityOccupied, ShelterStatus status,@ShelterResourcesConverter() ShelterResources resources, List<String> photos, String createdBy, String? managedBy, String? organizationId, ValidationStatus validationStatus, String? validatedBy, int unsafeReportsCount,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});


$ShelterResourcesCopyWith<$Res> get resources;

}
/// @nodoc
class _$ShelterCopyWithImpl<$Res>
    implements $ShelterCopyWith<$Res> {
  _$ShelterCopyWithImpl(this._self, this._then);

  final Shelter _self;
  final $Res Function(Shelter) _then;

/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? location = null,Object? address = null,Object? capacityTotal = null,Object? capacityOccupied = null,Object? status = null,Object? resources = null,Object? photos = null,Object? createdBy = null,Object? managedBy = freezed,Object? organizationId = freezed,Object? validationStatus = null,Object? validatedBy = freezed,Object? unsafeReportsCount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Shelter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,capacityTotal: null == capacityTotal ? _self.capacityTotal : capacityTotal // ignore: cast_nullable_to_non_nullable
as int,capacityOccupied: null == capacityOccupied ? _self.capacityOccupied : capacityOccupied // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShelterStatus,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as ShelterResources,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,managedBy: freezed == managedBy ? _self.managedBy : managedBy // ignore: cast_nullable_to_non_nullable
as String?,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,validationStatus: null == validationStatus ? _self.validationStatus : validationStatus // ignore: cast_nullable_to_non_nullable
as ValidationStatus,validatedBy: freezed == validatedBy ? _self.validatedBy : validatedBy // ignore: cast_nullable_to_non_nullable
as String?,unsafeReportsCount: null == unsafeReportsCount ? _self.unsafeReportsCount : unsafeReportsCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShelterResourcesCopyWith<$Res> get resources {
  
  return $ShelterResourcesCopyWith<$Res>(_self.resources, (value) {
    return _then(_self.copyWith(resources: value));
  });
}
}


/// Adds pattern-matching-related methods to [Shelter].
extension ShelterPatterns on Shelter {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shelter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shelter() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shelter value)  $default,){
final _that = this;
switch (_that) {
case _Shelter():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shelter value)?  $default,){
final _that = this;
switch (_that) {
case _Shelter() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @GeoPointConverter()  GeoPoint location,  String address,  int capacityTotal,  int capacityOccupied,  ShelterStatus status, @ShelterResourcesConverter()  ShelterResources resources,  List<String> photos,  String createdBy,  String? managedBy,  String? organizationId,  ValidationStatus validationStatus,  String? validatedBy,  int unsafeReportsCount, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shelter() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.address,_that.capacityTotal,_that.capacityOccupied,_that.status,_that.resources,_that.photos,_that.createdBy,_that.managedBy,_that.organizationId,_that.validationStatus,_that.validatedBy,_that.unsafeReportsCount,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @GeoPointConverter()  GeoPoint location,  String address,  int capacityTotal,  int capacityOccupied,  ShelterStatus status, @ShelterResourcesConverter()  ShelterResources resources,  List<String> photos,  String createdBy,  String? managedBy,  String? organizationId,  ValidationStatus validationStatus,  String? validatedBy,  int unsafeReportsCount, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Shelter():
return $default(_that.id,_that.name,_that.location,_that.address,_that.capacityTotal,_that.capacityOccupied,_that.status,_that.resources,_that.photos,_that.createdBy,_that.managedBy,_that.organizationId,_that.validationStatus,_that.validatedBy,_that.unsafeReportsCount,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @GeoPointConverter()  GeoPoint location,  String address,  int capacityTotal,  int capacityOccupied,  ShelterStatus status, @ShelterResourcesConverter()  ShelterResources resources,  List<String> photos,  String createdBy,  String? managedBy,  String? organizationId,  ValidationStatus validationStatus,  String? validatedBy,  int unsafeReportsCount, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Shelter() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.address,_that.capacityTotal,_that.capacityOccupied,_that.status,_that.resources,_that.photos,_that.createdBy,_that.managedBy,_that.organizationId,_that.validationStatus,_that.validatedBy,_that.unsafeReportsCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shelter implements Shelter {
  const _Shelter({required this.id, required this.name, @GeoPointConverter() required this.location, required this.address, required this.capacityTotal, this.capacityOccupied = 0, required this.status, @ShelterResourcesConverter() required this.resources,  List<String> photos = const [], required this.createdBy, this.managedBy, this.organizationId, this.validationStatus = ValidationStatus.pending, this.validatedBy, this.unsafeReportsCount = 0, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt}): _photos = photos;
  factory _Shelter.fromJson(Map<String, dynamic> json) => _$ShelterFromJson(json);

@override final  String id;
@override final  String name;
@override@GeoPointConverter() final  GeoPoint location;
@override final  String address;
@override final  int capacityTotal;
@override@JsonKey() final  int capacityOccupied;
@override final  ShelterStatus status;
@override@ShelterResourcesConverter() final  ShelterResources resources;
 final  List<String> _photos;
@override@JsonKey() List<String> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  String createdBy;
@override final  String? managedBy;
@override final  String? organizationId;
@override@JsonKey() final  ValidationStatus validationStatus;
@override final  String? validatedBy;
@override@JsonKey() final  int unsafeReportsCount;
@override@TimestampConverter() final  DateTime createdAt;
@override@TimestampConverter() final  DateTime updatedAt;

/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShelterCopyWith<_Shelter> get copyWith => __$ShelterCopyWithImpl<_Shelter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShelterToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shelter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address)&&(identical(other.capacityTotal, capacityTotal) || other.capacityTotal == capacityTotal)&&(identical(other.capacityOccupied, capacityOccupied) || other.capacityOccupied == capacityOccupied)&&(identical(other.status, status) || other.status == status)&&(identical(other.resources, resources) || other.resources == resources)&&const DeepCollectionEquality().equals(other.photos, _photos)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.managedBy, managedBy) || other.managedBy == managedBy)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.validationStatus, validationStatus) || other.validationStatus == validationStatus)&&(identical(other.validatedBy, validatedBy) || other.validatedBy == validatedBy)&&(identical(other.unsafeReportsCount, unsafeReportsCount) || other.unsafeReportsCount == unsafeReportsCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,location,address,capacityTotal,capacityOccupied,status,resources,const DeepCollectionEquality().hash(_photos),createdBy,managedBy,organizationId,validationStatus,validatedBy,unsafeReportsCount,createdAt,updatedAt);
}

@override
String toString() {
    return 'Shelter(id: $id, name: $name, location: $location, address: $address, capacityTotal: $capacityTotal, capacityOccupied: $capacityOccupied, status: $status, resources: $resources, photos: $photos, createdBy: $createdBy, managedBy: $managedBy, organizationId: $organizationId, validationStatus: $validationStatus, validatedBy: $validatedBy, unsafeReportsCount: $unsafeReportsCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShelterCopyWith<$Res> implements $ShelterCopyWith<$Res> {
  factory _$ShelterCopyWith(_Shelter value, $Res Function(_Shelter) _then) = __$ShelterCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@GeoPointConverter() GeoPoint location, String address, int capacityTotal, int capacityOccupied, ShelterStatus status,@ShelterResourcesConverter() ShelterResources resources, List<String> photos, String createdBy, String? managedBy, String? organizationId, ValidationStatus validationStatus, String? validatedBy, int unsafeReportsCount,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});


@override $ShelterResourcesCopyWith<$Res> get resources;

}
/// @nodoc
class __$ShelterCopyWithImpl<$Res>
    implements _$ShelterCopyWith<$Res> {
  __$ShelterCopyWithImpl(this._self, this._then);

  final _Shelter _self;
  final $Res Function(_Shelter) _then;

/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? location = null,Object? address = null,Object? capacityTotal = null,Object? capacityOccupied = null,Object? status = null,Object? resources = null,Object? photos = null,Object? createdBy = null,Object? managedBy = freezed,Object? organizationId = freezed,Object? validationStatus = null,Object? validatedBy = freezed,Object? unsafeReportsCount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Shelter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,capacityTotal: null == capacityTotal ? _self.capacityTotal : capacityTotal // ignore: cast_nullable_to_non_nullable
as int,capacityOccupied: null == capacityOccupied ? _self.capacityOccupied : capacityOccupied // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShelterStatus,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as ShelterResources,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,managedBy: freezed == managedBy ? _self.managedBy : managedBy // ignore: cast_nullable_to_non_nullable
as String?,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,validationStatus: null == validationStatus ? _self.validationStatus : validationStatus // ignore: cast_nullable_to_non_nullable
as ValidationStatus,validatedBy: freezed == validatedBy ? _self.validatedBy : validatedBy // ignore: cast_nullable_to_non_nullable
as String?,unsafeReportsCount: null == unsafeReportsCount ? _self.unsafeReportsCount : unsafeReportsCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShelterResourcesCopyWith<$Res> get resources {
  
  return $ShelterResourcesCopyWith<$Res>(_self.resources, (value) {
    return _then(_self.copyWith(resources: value));
  });
}
}

// dart format on
