// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_share_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocationShare {

 String get id; String get sosAlertId; String get userId;@GeoPointConverter() GeoPoint get currentLocation; bool get isActive;@TimestampConverter() DateTime get updatedAt;
/// Create a copy of LocationShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationShareCopyWith<LocationShare> get copyWith => _$LocationShareCopyWithImpl<LocationShare>(this as LocationShare, _$identity);

  /// Serializes this LocationShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LocationShare;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationShare&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sosAlertId, _this.sosAlertId) || other.sosAlertId == _this.sosAlertId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.currentLocation, _this.currentLocation) || other.currentLocation == _this.currentLocation)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LocationShare;
  return Object.hash(runtimeType,_this.id,_this.sosAlertId,_this.userId,_this.currentLocation,_this.isActive,_this.updatedAt);
}

@override
String toString() {
  final _this = this as LocationShare;
  return 'LocationShare(id: ${_this.id}, sosAlertId: ${_this.sosAlertId}, userId: ${_this.userId}, currentLocation: ${_this.currentLocation}, isActive: ${_this.isActive}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $LocationShareCopyWith<$Res>  {
  factory $LocationShareCopyWith(LocationShare value, $Res Function(LocationShare) _then) = _$LocationShareCopyWithImpl;
@useResult
$Res call({
 String id, String sosAlertId, String userId,@GeoPointConverter() GeoPoint currentLocation, bool isActive,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class _$LocationShareCopyWithImpl<$Res>
    implements $LocationShareCopyWith<$Res> {
  _$LocationShareCopyWithImpl(this._self, this._then);

  final LocationShare _self;
  final $Res Function(LocationShare) _then;

/// Create a copy of LocationShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sosAlertId = null,Object? userId = null,Object? currentLocation = null,Object? isActive = null,Object? updatedAt = null,}) {
  return _then(LocationShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sosAlertId: null == sosAlertId ? _self.sosAlertId : sosAlertId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,currentLocation: null == currentLocation ? _self.currentLocation : currentLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LocationShare].
extension LocationSharePatterns on LocationShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocationShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocationShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocationShare value)  $default,){
final _that = this;
switch (_that) {
case _LocationShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocationShare value)?  $default,){
final _that = this;
switch (_that) {
case _LocationShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sosAlertId,  String userId, @GeoPointConverter()  GeoPoint currentLocation,  bool isActive, @TimestampConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocationShare() when $default != null:
return $default(_that.id,_that.sosAlertId,_that.userId,_that.currentLocation,_that.isActive,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sosAlertId,  String userId, @GeoPointConverter()  GeoPoint currentLocation,  bool isActive, @TimestampConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LocationShare():
return $default(_that.id,_that.sosAlertId,_that.userId,_that.currentLocation,_that.isActive,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sosAlertId,  String userId, @GeoPointConverter()  GeoPoint currentLocation,  bool isActive, @TimestampConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LocationShare() when $default != null:
return $default(_that.id,_that.sosAlertId,_that.userId,_that.currentLocation,_that.isActive,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocationShare implements LocationShare {
  const _LocationShare({required this.id, required this.sosAlertId, required this.userId, @GeoPointConverter() required this.currentLocation, this.isActive = true, @TimestampConverter() required this.updatedAt});
  factory _LocationShare.fromJson(Map<String, dynamic> json) => _$LocationShareFromJson(json);

@override final  String id;
@override final  String sosAlertId;
@override final  String userId;
@override@GeoPointConverter() final  GeoPoint currentLocation;
@override@JsonKey() final  bool isActive;
@override@TimestampConverter() final  DateTime updatedAt;

/// Create a copy of LocationShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationShareCopyWith<_LocationShare> get copyWith => __$LocationShareCopyWithImpl<_LocationShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationShareToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocationShare&&(identical(other.id, id) || other.id == id)&&(identical(other.sosAlertId, sosAlertId) || other.sosAlertId == sosAlertId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.currentLocation, currentLocation) || other.currentLocation == currentLocation)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,sosAlertId,userId,currentLocation,isActive,updatedAt);
}

@override
String toString() {
    return 'LocationShare(id: $id, sosAlertId: $sosAlertId, userId: $userId, currentLocation: $currentLocation, isActive: $isActive, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LocationShareCopyWith<$Res> implements $LocationShareCopyWith<$Res> {
  factory _$LocationShareCopyWith(_LocationShare value, $Res Function(_LocationShare) _then) = __$LocationShareCopyWithImpl;
@override @useResult
$Res call({
 String id, String sosAlertId, String userId,@GeoPointConverter() GeoPoint currentLocation, bool isActive,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class __$LocationShareCopyWithImpl<$Res>
    implements _$LocationShareCopyWith<$Res> {
  __$LocationShareCopyWithImpl(this._self, this._then);

  final _LocationShare _self;
  final $Res Function(_LocationShare) _then;

/// Create a copy of LocationShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sosAlertId = null,Object? userId = null,Object? currentLocation = null,Object? isActive = null,Object? updatedAt = null,}) {
  return _then(_LocationShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sosAlertId: null == sosAlertId ? _self.sosAlertId : sosAlertId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,currentLocation: null == currentLocation ? _self.currentLocation : currentLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
