// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'zone_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Zone {

 String get id; ZoneType get type; DisasterType? get disasterType;@GeoPointListConverter() List<GeoPoint> get geometry; Severity? get severity; ZoneOrigin get origin; String get source; String? get createdBy; String? get organizationId; bool get isActive;@TimestampConverter() DateTime get startedAt;@TimestampConverter() DateTime? get endedAt;
/// Create a copy of Zone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ZoneCopyWith<Zone> get copyWith => _$ZoneCopyWithImpl<Zone>(this as Zone, _$identity);

  /// Serializes this Zone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Zone;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Zone&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.disasterType, _this.disasterType) || other.disasterType == _this.disasterType)&&const DeepCollectionEquality().equals(other.geometry, _this.geometry)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Zone;
  return Object.hash(runtimeType,_this.id,_this.type,_this.disasterType,const DeepCollectionEquality().hash(_this.geometry),_this.severity,_this.origin,_this.source,_this.createdBy,_this.organizationId,_this.isActive,_this.startedAt,_this.endedAt);
}

@override
String toString() {
  final _this = this as Zone;
  return 'Zone(id: ${_this.id}, type: ${_this.type}, disasterType: ${_this.disasterType}, geometry: ${_this.geometry}, severity: ${_this.severity}, origin: ${_this.origin}, source: ${_this.source}, createdBy: ${_this.createdBy}, organizationId: ${_this.organizationId}, isActive: ${_this.isActive}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt})';
}


}

/// @nodoc
abstract mixin class $ZoneCopyWith<$Res>  {
  factory $ZoneCopyWith(Zone value, $Res Function(Zone) _then) = _$ZoneCopyWithImpl;
@useResult
$Res call({
 String id, ZoneType type, DisasterType? disasterType,@GeoPointListConverter() List<GeoPoint> geometry, Severity? severity, ZoneOrigin origin, String source, String? createdBy, String? organizationId, bool isActive,@TimestampConverter() DateTime startedAt,@TimestampConverter() DateTime? endedAt
});




}
/// @nodoc
class _$ZoneCopyWithImpl<$Res>
    implements $ZoneCopyWith<$Res> {
  _$ZoneCopyWithImpl(this._self, this._then);

  final Zone _self;
  final $Res Function(Zone) _then;

/// Create a copy of Zone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? disasterType = freezed,Object? geometry = null,Object? severity = freezed,Object? origin = null,Object? source = null,Object? createdBy = freezed,Object? organizationId = freezed,Object? isActive = null,Object? startedAt = null,Object? endedAt = freezed,}) {
  return _then(Zone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ZoneType,disasterType: freezed == disasterType ? _self.disasterType : disasterType // ignore: cast_nullable_to_non_nullable
as DisasterType?,geometry: null == geometry ? _self.geometry : geometry // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as Severity?,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ZoneOrigin,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Zone].
extension ZonePatterns on Zone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Zone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Zone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Zone value)  $default,){
final _that = this;
switch (_that) {
case _Zone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Zone value)?  $default,){
final _that = this;
switch (_that) {
case _Zone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ZoneType type,  DisasterType? disasterType, @GeoPointListConverter()  List<GeoPoint> geometry,  Severity? severity,  ZoneOrigin origin,  String source,  String? createdBy,  String? organizationId,  bool isActive, @TimestampConverter()  DateTime startedAt, @TimestampConverter()  DateTime? endedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Zone() when $default != null:
return $default(_that.id,_that.type,_that.disasterType,_that.geometry,_that.severity,_that.origin,_that.source,_that.createdBy,_that.organizationId,_that.isActive,_that.startedAt,_that.endedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ZoneType type,  DisasterType? disasterType, @GeoPointListConverter()  List<GeoPoint> geometry,  Severity? severity,  ZoneOrigin origin,  String source,  String? createdBy,  String? organizationId,  bool isActive, @TimestampConverter()  DateTime startedAt, @TimestampConverter()  DateTime? endedAt)  $default,) {final _that = this;
switch (_that) {
case _Zone():
return $default(_that.id,_that.type,_that.disasterType,_that.geometry,_that.severity,_that.origin,_that.source,_that.createdBy,_that.organizationId,_that.isActive,_that.startedAt,_that.endedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ZoneType type,  DisasterType? disasterType, @GeoPointListConverter()  List<GeoPoint> geometry,  Severity? severity,  ZoneOrigin origin,  String source,  String? createdBy,  String? organizationId,  bool isActive, @TimestampConverter()  DateTime startedAt, @TimestampConverter()  DateTime? endedAt)?  $default,) {final _that = this;
switch (_that) {
case _Zone() when $default != null:
return $default(_that.id,_that.type,_that.disasterType,_that.geometry,_that.severity,_that.origin,_that.source,_that.createdBy,_that.organizationId,_that.isActive,_that.startedAt,_that.endedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Zone implements Zone {
  const _Zone({required this.id, required this.type, this.disasterType, @GeoPointListConverter()  List<GeoPoint> geometry = const [], this.severity, required this.origin, required this.source, this.createdBy, this.organizationId, this.isActive = true, @TimestampConverter() required this.startedAt, @TimestampConverter() this.endedAt}): _geometry = geometry;
  factory _Zone.fromJson(Map<String, dynamic> json) => _$ZoneFromJson(json);

@override final  String id;
@override final  ZoneType type;
@override final  DisasterType? disasterType;
 final  List<GeoPoint> _geometry;
@override@JsonKey()@GeoPointListConverter() List<GeoPoint> get geometry {
  if (_geometry is EqualUnmodifiableListView) return _geometry;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_geometry);
}

@override final  Severity? severity;
@override final  ZoneOrigin origin;
@override final  String source;
@override final  String? createdBy;
@override final  String? organizationId;
@override@JsonKey() final  bool isActive;
@override@TimestampConverter() final  DateTime startedAt;
@override@TimestampConverter() final  DateTime? endedAt;

/// Create a copy of Zone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ZoneCopyWith<_Zone> get copyWith => __$ZoneCopyWithImpl<_Zone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ZoneToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Zone&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.disasterType, disasterType) || other.disasterType == disasterType)&&const DeepCollectionEquality().equals(other.geometry, _geometry)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,disasterType,const DeepCollectionEquality().hash(_geometry),severity,origin,source,createdBy,organizationId,isActive,startedAt,endedAt);
}

@override
String toString() {
    return 'Zone(id: $id, type: $type, disasterType: $disasterType, geometry: $geometry, severity: $severity, origin: $origin, source: $source, createdBy: $createdBy, organizationId: $organizationId, isActive: $isActive, startedAt: $startedAt, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class _$ZoneCopyWith<$Res> implements $ZoneCopyWith<$Res> {
  factory _$ZoneCopyWith(_Zone value, $Res Function(_Zone) _then) = __$ZoneCopyWithImpl;
@override @useResult
$Res call({
 String id, ZoneType type, DisasterType? disasterType,@GeoPointListConverter() List<GeoPoint> geometry, Severity? severity, ZoneOrigin origin, String source, String? createdBy, String? organizationId, bool isActive,@TimestampConverter() DateTime startedAt,@TimestampConverter() DateTime? endedAt
});




}
/// @nodoc
class __$ZoneCopyWithImpl<$Res>
    implements _$ZoneCopyWith<$Res> {
  __$ZoneCopyWithImpl(this._self, this._then);

  final _Zone _self;
  final $Res Function(_Zone) _then;

/// Create a copy of Zone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? disasterType = freezed,Object? geometry = null,Object? severity = freezed,Object? origin = null,Object? source = null,Object? createdBy = freezed,Object? organizationId = freezed,Object? isActive = null,Object? startedAt = null,Object? endedAt = freezed,}) {
  return _then(_Zone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ZoneType,disasterType: freezed == disasterType ? _self.disasterType : disasterType // ignore: cast_nullable_to_non_nullable
as DisasterType?,geometry: null == geometry ? _self._geometry : geometry // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as Severity?,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ZoneOrigin,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
