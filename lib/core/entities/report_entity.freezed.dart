// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Report {

 String get id; String get reporterId; ReportTargetType get targetType; String get targetId; ReportReason get reason; String? get description; ReportStatus get status; String? get reviewedBy;@TimestampConverter() DateTime get createdAt;
/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportCopyWith<Report> get copyWith => _$ReportCopyWithImpl<Report>(this as Report, _$identity);

  /// Serializes this Report to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Report;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Report&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.reporterId, _this.reporterId) || other.reporterId == _this.reporterId)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&(identical(other.targetId, _this.targetId) || other.targetId == _this.targetId)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reviewedBy, _this.reviewedBy) || other.reviewedBy == _this.reviewedBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Report;
  return Object.hash(runtimeType,_this.id,_this.reporterId,_this.targetType,_this.targetId,_this.reason,_this.description,_this.status,_this.reviewedBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as Report;
  return 'Report(id: ${_this.id}, reporterId: ${_this.reporterId}, targetType: ${_this.targetType}, targetId: ${_this.targetId}, reason: ${_this.reason}, description: ${_this.description}, status: ${_this.status}, reviewedBy: ${_this.reviewedBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ReportCopyWith<$Res>  {
  factory $ReportCopyWith(Report value, $Res Function(Report) _then) = _$ReportCopyWithImpl;
@useResult
$Res call({
 String id, String reporterId, ReportTargetType targetType, String targetId, ReportReason reason, String? description, ReportStatus status, String? reviewedBy,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$ReportCopyWithImpl<$Res>
    implements $ReportCopyWith<$Res> {
  _$ReportCopyWithImpl(this._self, this._then);

  final Report _self;
  final $Res Function(Report) _then;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reporterId = null,Object? targetType = null,Object? targetId = null,Object? reason = null,Object? description = freezed,Object? status = null,Object? reviewedBy = freezed,Object? createdAt = null,}) {
  return _then(Report(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ReportTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReportStatus,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Report].
extension ReportPatterns on Report {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Report value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Report() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Report value)  $default,){
final _that = this;
switch (_that) {
case _Report():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Report value)?  $default,){
final _that = this;
switch (_that) {
case _Report() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String reporterId,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String? description,  ReportStatus status,  String? reviewedBy, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that.id,_that.reporterId,_that.targetType,_that.targetId,_that.reason,_that.description,_that.status,_that.reviewedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String reporterId,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String? description,  ReportStatus status,  String? reviewedBy, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Report():
return $default(_that.id,_that.reporterId,_that.targetType,_that.targetId,_that.reason,_that.description,_that.status,_that.reviewedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String reporterId,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String? description,  ReportStatus status,  String? reviewedBy, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that.id,_that.reporterId,_that.targetType,_that.targetId,_that.reason,_that.description,_that.status,_that.reviewedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Report implements Report {
  const _Report({required this.id, required this.reporterId, required this.targetType, required this.targetId, required this.reason, this.description, this.status = ReportStatus.open, this.reviewedBy, @TimestampConverter() required this.createdAt});
  factory _Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);

@override final  String id;
@override final  String reporterId;
@override final  ReportTargetType targetType;
@override final  String targetId;
@override final  ReportReason reason;
@override final  String? description;
@override@JsonKey() final  ReportStatus status;
@override final  String? reviewedBy;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportCopyWith<_Report> get copyWith => __$ReportCopyWithImpl<_Report>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Report&&(identical(other.id, id) || other.id == id)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,reporterId,targetType,targetId,reason,description,status,reviewedBy,createdAt);
}

@override
String toString() {
    return 'Report(id: $id, reporterId: $reporterId, targetType: $targetType, targetId: $targetId, reason: $reason, description: $description, status: $status, reviewedBy: $reviewedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ReportCopyWith<$Res> implements $ReportCopyWith<$Res> {
  factory _$ReportCopyWith(_Report value, $Res Function(_Report) _then) = __$ReportCopyWithImpl;
@override @useResult
$Res call({
 String id, String reporterId, ReportTargetType targetType, String targetId, ReportReason reason, String? description, ReportStatus status, String? reviewedBy,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$ReportCopyWithImpl<$Res>
    implements _$ReportCopyWith<$Res> {
  __$ReportCopyWithImpl(this._self, this._then);

  final _Report _self;
  final $Res Function(_Report) _then;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reporterId = null,Object? targetType = null,Object? targetId = null,Object? reason = null,Object? description = freezed,Object? status = null,Object? reviewedBy = freezed,Object? createdAt = null,}) {
  return _then(_Report(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ReportTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReportStatus,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
