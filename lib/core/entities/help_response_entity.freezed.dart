// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'help_response_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HelpResponse {

 String get id; String get sosAlertId; String get responderId; ResponseType get responseType; String? get message; HelpResponseStatus get status;@TimestampConverter() DateTime get createdAt;@TimestampConverter() DateTime get updatedAt;
/// Create a copy of HelpResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpResponseCopyWith<HelpResponse> get copyWith => _$HelpResponseCopyWithImpl<HelpResponse>(this as HelpResponse, _$identity);

  /// Serializes this HelpResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HelpResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpResponse&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sosAlertId, _this.sosAlertId) || other.sosAlertId == _this.sosAlertId)&&(identical(other.responderId, _this.responderId) || other.responderId == _this.responderId)&&(identical(other.responseType, _this.responseType) || other.responseType == _this.responseType)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HelpResponse;
  return Object.hash(runtimeType,_this.id,_this.sosAlertId,_this.responderId,_this.responseType,_this.message,_this.status,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as HelpResponse;
  return 'HelpResponse(id: ${_this.id}, sosAlertId: ${_this.sosAlertId}, responderId: ${_this.responderId}, responseType: ${_this.responseType}, message: ${_this.message}, status: ${_this.status}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $HelpResponseCopyWith<$Res>  {
  factory $HelpResponseCopyWith(HelpResponse value, $Res Function(HelpResponse) _then) = _$HelpResponseCopyWithImpl;
@useResult
$Res call({
 String id, String sosAlertId, String responderId, ResponseType responseType, String? message, HelpResponseStatus status,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class _$HelpResponseCopyWithImpl<$Res>
    implements $HelpResponseCopyWith<$Res> {
  _$HelpResponseCopyWithImpl(this._self, this._then);

  final HelpResponse _self;
  final $Res Function(HelpResponse) _then;

/// Create a copy of HelpResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sosAlertId = null,Object? responderId = null,Object? responseType = null,Object? message = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(HelpResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sosAlertId: null == sosAlertId ? _self.sosAlertId : sosAlertId // ignore: cast_nullable_to_non_nullable
as String,responderId: null == responderId ? _self.responderId : responderId // ignore: cast_nullable_to_non_nullable
as String,responseType: null == responseType ? _self.responseType : responseType // ignore: cast_nullable_to_non_nullable
as ResponseType,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HelpResponseStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [HelpResponse].
extension HelpResponsePatterns on HelpResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpResponse value)  $default,){
final _that = this;
switch (_that) {
case _HelpResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpResponse value)?  $default,){
final _that = this;
switch (_that) {
case _HelpResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sosAlertId,  String responderId,  ResponseType responseType,  String? message,  HelpResponseStatus status, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpResponse() when $default != null:
return $default(_that.id,_that.sosAlertId,_that.responderId,_that.responseType,_that.message,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sosAlertId,  String responderId,  ResponseType responseType,  String? message,  HelpResponseStatus status, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _HelpResponse():
return $default(_that.id,_that.sosAlertId,_that.responderId,_that.responseType,_that.message,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sosAlertId,  String responderId,  ResponseType responseType,  String? message,  HelpResponseStatus status, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _HelpResponse() when $default != null:
return $default(_that.id,_that.sosAlertId,_that.responderId,_that.responseType,_that.message,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelpResponse implements HelpResponse {
  const _HelpResponse({required this.id, required this.sosAlertId, required this.responderId, required this.responseType, this.message, this.status = HelpResponseStatus.offered, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt});
  factory _HelpResponse.fromJson(Map<String, dynamic> json) => _$HelpResponseFromJson(json);

@override final  String id;
@override final  String sosAlertId;
@override final  String responderId;
@override final  ResponseType responseType;
@override final  String? message;
@override@JsonKey() final  HelpResponseStatus status;
@override@TimestampConverter() final  DateTime createdAt;
@override@TimestampConverter() final  DateTime updatedAt;

/// Create a copy of HelpResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpResponseCopyWith<_HelpResponse> get copyWith => __$HelpResponseCopyWithImpl<_HelpResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelpResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.sosAlertId, sosAlertId) || other.sosAlertId == sosAlertId)&&(identical(other.responderId, responderId) || other.responderId == responderId)&&(identical(other.responseType, responseType) || other.responseType == responseType)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,sosAlertId,responderId,responseType,message,status,createdAt,updatedAt);
}

@override
String toString() {
    return 'HelpResponse(id: $id, sosAlertId: $sosAlertId, responderId: $responderId, responseType: $responseType, message: $message, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HelpResponseCopyWith<$Res> implements $HelpResponseCopyWith<$Res> {
  factory _$HelpResponseCopyWith(_HelpResponse value, $Res Function(_HelpResponse) _then) = __$HelpResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, String sosAlertId, String responderId, ResponseType responseType, String? message, HelpResponseStatus status,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class __$HelpResponseCopyWithImpl<$Res>
    implements _$HelpResponseCopyWith<$Res> {
  __$HelpResponseCopyWithImpl(this._self, this._then);

  final _HelpResponse _self;
  final $Res Function(_HelpResponse) _then;

/// Create a copy of HelpResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sosAlertId = null,Object? responderId = null,Object? responseType = null,Object? message = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_HelpResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sosAlertId: null == sosAlertId ? _self.sosAlertId : sosAlertId // ignore: cast_nullable_to_non_nullable
as String,responderId: null == responderId ? _self.responderId : responderId // ignore: cast_nullable_to_non_nullable
as String,responseType: null == responseType ? _self.responseType : responseType // ignore: cast_nullable_to_non_nullable
as ResponseType,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HelpResponseStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
