// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'disaster_alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DisasterAlert {

/// Stable : `<zoneId>-<severity>`. Un changement de niveau (orange -> rouge)
/// produit donc une NOUVELLE alerte, une simple mise à jour de position non.
 String get id; String get zoneId; DisasterType get disasterType; Severity? get severity; String get title; String get message; double get distanceKm; double get bearingDeg; bool get approaching; bool get userInsideZone; DateTime get createdAt;
/// Create a copy of DisasterAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DisasterAlertCopyWith<DisasterAlert> get copyWith => _$DisasterAlertCopyWithImpl<DisasterAlert>(this as DisasterAlert, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DisasterAlert;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisasterAlert&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.zoneId, _this.zoneId) || other.zoneId == _this.zoneId)&&(identical(other.disasterType, _this.disasterType) || other.disasterType == _this.disasterType)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.bearingDeg, _this.bearingDeg) || other.bearingDeg == _this.bearingDeg)&&(identical(other.approaching, _this.approaching) || other.approaching == _this.approaching)&&(identical(other.userInsideZone, _this.userInsideZone) || other.userInsideZone == _this.userInsideZone)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as DisasterAlert;
  return Object.hash(runtimeType,_this.id,_this.zoneId,_this.disasterType,_this.severity,_this.title,_this.message,_this.distanceKm,_this.bearingDeg,_this.approaching,_this.userInsideZone,_this.createdAt);
}

@override
String toString() {
  final _this = this as DisasterAlert;
  return 'DisasterAlert(id: ${_this.id}, zoneId: ${_this.zoneId}, disasterType: ${_this.disasterType}, severity: ${_this.severity}, title: ${_this.title}, message: ${_this.message}, distanceKm: ${_this.distanceKm}, bearingDeg: ${_this.bearingDeg}, approaching: ${_this.approaching}, userInsideZone: ${_this.userInsideZone}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $DisasterAlertCopyWith<$Res>  {
  factory $DisasterAlertCopyWith(DisasterAlert value, $Res Function(DisasterAlert) _then) = _$DisasterAlertCopyWithImpl;
@useResult
$Res call({
 String id, String zoneId, DisasterType disasterType, Severity? severity, String title, String message, double distanceKm, double bearingDeg, bool approaching, bool userInsideZone, DateTime createdAt
});




}
/// @nodoc
class _$DisasterAlertCopyWithImpl<$Res>
    implements $DisasterAlertCopyWith<$Res> {
  _$DisasterAlertCopyWithImpl(this._self, this._then);

  final DisasterAlert _self;
  final $Res Function(DisasterAlert) _then;

/// Create a copy of DisasterAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? zoneId = null,Object? disasterType = null,Object? severity = freezed,Object? title = null,Object? message = null,Object? distanceKm = null,Object? bearingDeg = null,Object? approaching = null,Object? userInsideZone = null,Object? createdAt = null,}) {
  return _then(DisasterAlert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,zoneId: null == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String,disasterType: null == disasterType ? _self.disasterType : disasterType // ignore: cast_nullable_to_non_nullable
as DisasterType,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as Severity?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,bearingDeg: null == bearingDeg ? _self.bearingDeg : bearingDeg // ignore: cast_nullable_to_non_nullable
as double,approaching: null == approaching ? _self.approaching : approaching // ignore: cast_nullable_to_non_nullable
as bool,userInsideZone: null == userInsideZone ? _self.userInsideZone : userInsideZone // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DisasterAlert].
extension DisasterAlertPatterns on DisasterAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DisasterAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DisasterAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DisasterAlert value)  $default,){
final _that = this;
switch (_that) {
case _DisasterAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DisasterAlert value)?  $default,){
final _that = this;
switch (_that) {
case _DisasterAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String zoneId,  DisasterType disasterType,  Severity? severity,  String title,  String message,  double distanceKm,  double bearingDeg,  bool approaching,  bool userInsideZone,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DisasterAlert() when $default != null:
return $default(_that.id,_that.zoneId,_that.disasterType,_that.severity,_that.title,_that.message,_that.distanceKm,_that.bearingDeg,_that.approaching,_that.userInsideZone,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String zoneId,  DisasterType disasterType,  Severity? severity,  String title,  String message,  double distanceKm,  double bearingDeg,  bool approaching,  bool userInsideZone,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _DisasterAlert():
return $default(_that.id,_that.zoneId,_that.disasterType,_that.severity,_that.title,_that.message,_that.distanceKm,_that.bearingDeg,_that.approaching,_that.userInsideZone,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String zoneId,  DisasterType disasterType,  Severity? severity,  String title,  String message,  double distanceKm,  double bearingDeg,  bool approaching,  bool userInsideZone,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DisasterAlert() when $default != null:
return $default(_that.id,_that.zoneId,_that.disasterType,_that.severity,_that.title,_that.message,_that.distanceKm,_that.bearingDeg,_that.approaching,_that.userInsideZone,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _DisasterAlert implements DisasterAlert {
  const _DisasterAlert({required this.id, required this.zoneId, required this.disasterType, this.severity, required this.title, required this.message, required this.distanceKm, required this.bearingDeg, required this.approaching, required this.userInsideZone, required this.createdAt});
  

/// Stable : `<zoneId>-<severity>`. Un changement de niveau (orange -> rouge)
/// produit donc une NOUVELLE alerte, une simple mise à jour de position non.
@override final  String id;
@override final  String zoneId;
@override final  DisasterType disasterType;
@override final  Severity? severity;
@override final  String title;
@override final  String message;
@override final  double distanceKm;
@override final  double bearingDeg;
@override final  bool approaching;
@override final  bool userInsideZone;
@override final  DateTime createdAt;

/// Create a copy of DisasterAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DisasterAlertCopyWith<_DisasterAlert> get copyWith => __$DisasterAlertCopyWithImpl<_DisasterAlert>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DisasterAlert&&(identical(other.id, id) || other.id == id)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.disasterType, disasterType) || other.disasterType == disasterType)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bearingDeg, bearingDeg) || other.bearingDeg == bearingDeg)&&(identical(other.approaching, approaching) || other.approaching == approaching)&&(identical(other.userInsideZone, userInsideZone) || other.userInsideZone == userInsideZone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,zoneId,disasterType,severity,title,message,distanceKm,bearingDeg,approaching,userInsideZone,createdAt);
}

@override
String toString() {
    return 'DisasterAlert(id: $id, zoneId: $zoneId, disasterType: $disasterType, severity: $severity, title: $title, message: $message, distanceKm: $distanceKm, bearingDeg: $bearingDeg, approaching: $approaching, userInsideZone: $userInsideZone, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DisasterAlertCopyWith<$Res> implements $DisasterAlertCopyWith<$Res> {
  factory _$DisasterAlertCopyWith(_DisasterAlert value, $Res Function(_DisasterAlert) _then) = __$DisasterAlertCopyWithImpl;
@override @useResult
$Res call({
 String id, String zoneId, DisasterType disasterType, Severity? severity, String title, String message, double distanceKm, double bearingDeg, bool approaching, bool userInsideZone, DateTime createdAt
});




}
/// @nodoc
class __$DisasterAlertCopyWithImpl<$Res>
    implements _$DisasterAlertCopyWith<$Res> {
  __$DisasterAlertCopyWithImpl(this._self, this._then);

  final _DisasterAlert _self;
  final $Res Function(_DisasterAlert) _then;

/// Create a copy of DisasterAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? zoneId = null,Object? disasterType = null,Object? severity = freezed,Object? title = null,Object? message = null,Object? distanceKm = null,Object? bearingDeg = null,Object? approaching = null,Object? userInsideZone = null,Object? createdAt = null,}) {
  return _then(_DisasterAlert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,zoneId: null == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String,disasterType: null == disasterType ? _self.disasterType : disasterType // ignore: cast_nullable_to_non_nullable
as DisasterType,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as Severity?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,bearingDeg: null == bearingDeg ? _self.bearingDeg : bearingDeg // ignore: cast_nullable_to_non_nullable
as double,approaching: null == approaching ? _self.approaching : approaching // ignore: cast_nullable_to_non_nullable
as bool,userInsideZone: null == userInsideZone ? _self.userInsideZone : userInsideZone // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
