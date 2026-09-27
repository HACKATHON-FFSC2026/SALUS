// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sos_alert_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SOSAlert {

 String get id; String get userId;@GeoPointConverter() GeoPoint get location; DistressType get distressType; String? get description; SOSStatus get status; int get respondersCount; String? get assignedOrganizationId;@TimestampConverter() DateTime get createdAt;@TimestampConverter() DateTime? get resolvedAt;
/// Create a copy of SOSAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SOSAlertCopyWith<SOSAlert> get copyWith => _$SOSAlertCopyWithImpl<SOSAlert>(this as SOSAlert, _$identity);

  /// Serializes this SOSAlert to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SOSAlert;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SOSAlert&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.distressType, _this.distressType) || other.distressType == _this.distressType)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.respondersCount, _this.respondersCount) || other.respondersCount == _this.respondersCount)&&(identical(other.assignedOrganizationId, _this.assignedOrganizationId) || other.assignedOrganizationId == _this.assignedOrganizationId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.resolvedAt, _this.resolvedAt) || other.resolvedAt == _this.resolvedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SOSAlert;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.location,_this.distressType,_this.description,_this.status,_this.respondersCount,_this.assignedOrganizationId,_this.createdAt,_this.resolvedAt);
}

@override
String toString() {
  final _this = this as SOSAlert;
  return 'SOSAlert(id: ${_this.id}, userId: ${_this.userId}, location: ${_this.location}, distressType: ${_this.distressType}, description: ${_this.description}, status: ${_this.status}, respondersCount: ${_this.respondersCount}, assignedOrganizationId: ${_this.assignedOrganizationId}, createdAt: ${_this.createdAt}, resolvedAt: ${_this.resolvedAt})';
}


}

/// @nodoc
abstract mixin class $SOSAlertCopyWith<$Res>  {
  factory $SOSAlertCopyWith(SOSAlert value, $Res Function(SOSAlert) _then) = _$SOSAlertCopyWithImpl;
@useResult
$Res call({
 String id, String userId,@GeoPointConverter() GeoPoint location, DistressType distressType, String? description, SOSStatus status, int respondersCount, String? assignedOrganizationId,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime? resolvedAt
});




}
/// @nodoc
class _$SOSAlertCopyWithImpl<$Res>
    implements $SOSAlertCopyWith<$Res> {
  _$SOSAlertCopyWithImpl(this._self, this._then);

  final SOSAlert _self;
  final $Res Function(SOSAlert) _then;

/// Create a copy of SOSAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? location = null,Object? distressType = null,Object? description = freezed,Object? status = null,Object? respondersCount = null,Object? assignedOrganizationId = freezed,Object? createdAt = null,Object? resolvedAt = freezed,}) {
  return _then(SOSAlert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,distressType: null == distressType ? _self.distressType : distressType // ignore: cast_nullable_to_non_nullable
as DistressType,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SOSStatus,respondersCount: null == respondersCount ? _self.respondersCount : respondersCount // ignore: cast_nullable_to_non_nullable
as int,assignedOrganizationId: freezed == assignedOrganizationId ? _self.assignedOrganizationId : assignedOrganizationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SOSAlert].
extension SOSAlertPatterns on SOSAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SOSAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SOSAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SOSAlert value)  $default,){
final _that = this;
switch (_that) {
case _SOSAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SOSAlert value)?  $default,){
final _that = this;
switch (_that) {
case _SOSAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId, @GeoPointConverter()  GeoPoint location,  DistressType distressType,  String? description,  SOSStatus status,  int respondersCount,  String? assignedOrganizationId, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime? resolvedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SOSAlert() when $default != null:
return $default(_that.id,_that.userId,_that.location,_that.distressType,_that.description,_that.status,_that.respondersCount,_that.assignedOrganizationId,_that.createdAt,_that.resolvedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId, @GeoPointConverter()  GeoPoint location,  DistressType distressType,  String? description,  SOSStatus status,  int respondersCount,  String? assignedOrganizationId, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime? resolvedAt)  $default,) {final _that = this;
switch (_that) {
case _SOSAlert():
return $default(_that.id,_that.userId,_that.location,_that.distressType,_that.description,_that.status,_that.respondersCount,_that.assignedOrganizationId,_that.createdAt,_that.resolvedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId, @GeoPointConverter()  GeoPoint location,  DistressType distressType,  String? description,  SOSStatus status,  int respondersCount,  String? assignedOrganizationId, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime? resolvedAt)?  $default,) {final _that = this;
switch (_that) {
case _SOSAlert() when $default != null:
return $default(_that.id,_that.userId,_that.location,_that.distressType,_that.description,_that.status,_that.respondersCount,_that.assignedOrganizationId,_that.createdAt,_that.resolvedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SOSAlert implements SOSAlert {
  const _SOSAlert({required this.id, required this.userId, @GeoPointConverter() required this.location, required this.distressType, this.description, this.status = SOSStatus.waiting, this.respondersCount = 0, this.assignedOrganizationId, @TimestampConverter() required this.createdAt, @TimestampConverter() this.resolvedAt});
  factory _SOSAlert.fromJson(Map<String, dynamic> json) => _$SOSAlertFromJson(json);

@override final  String id;
@override final  String userId;
@override@GeoPointConverter() final  GeoPoint location;
@override final  DistressType distressType;
@override final  String? description;
@override@JsonKey() final  SOSStatus status;
@override@JsonKey() final  int respondersCount;
@override final  String? assignedOrganizationId;
@override@TimestampConverter() final  DateTime createdAt;
@override@TimestampConverter() final  DateTime? resolvedAt;

/// Create a copy of SOSAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SOSAlertCopyWith<_SOSAlert> get copyWith => __$SOSAlertCopyWithImpl<_SOSAlert>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SOSAlertToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SOSAlert&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.location, location) || other.location == location)&&(identical(other.distressType, distressType) || other.distressType == distressType)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.respondersCount, respondersCount) || other.respondersCount == respondersCount)&&(identical(other.assignedOrganizationId, assignedOrganizationId) || other.assignedOrganizationId == assignedOrganizationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,location,distressType,description,status,respondersCount,assignedOrganizationId,createdAt,resolvedAt);
}

@override
String toString() {
    return 'SOSAlert(id: $id, userId: $userId, location: $location, distressType: $distressType, description: $description, status: $status, respondersCount: $respondersCount, assignedOrganizationId: $assignedOrganizationId, createdAt: $createdAt, resolvedAt: $resolvedAt)';
}


}

/// @nodoc
abstract mixin class _$SOSAlertCopyWith<$Res> implements $SOSAlertCopyWith<$Res> {
  factory _$SOSAlertCopyWith(_SOSAlert value, $Res Function(_SOSAlert) _then) = __$SOSAlertCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId,@GeoPointConverter() GeoPoint location, DistressType distressType, String? description, SOSStatus status, int respondersCount, String? assignedOrganizationId,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime? resolvedAt
});




}
/// @nodoc
class __$SOSAlertCopyWithImpl<$Res>
    implements _$SOSAlertCopyWith<$Res> {
  __$SOSAlertCopyWithImpl(this._self, this._then);

  final _SOSAlert _self;
  final $Res Function(_SOSAlert) _then;

/// Create a copy of SOSAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? location = null,Object? distressType = null,Object? description = freezed,Object? status = null,Object? respondersCount = null,Object? assignedOrganizationId = freezed,Object? createdAt = null,Object? resolvedAt = freezed,}) {
  return _then(_SOSAlert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,distressType: null == distressType ? _self.distressType : distressType // ignore: cast_nullable_to_non_nullable
as DistressType,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SOSStatus,respondersCount: null == respondersCount ? _self.respondersCount : respondersCount // ignore: cast_nullable_to_non_nullable
as int,assignedOrganizationId: freezed == assignedOrganizationId ? _self.assignedOrganizationId : assignedOrganizationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
