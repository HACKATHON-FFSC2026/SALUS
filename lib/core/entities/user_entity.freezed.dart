// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

 String get id; String get displayName; String get email; String? get phoneNumber; AuthProvider get authProvider; List<UserRole> get roles; String? get organizationId; CompetencyTag? get competencyTag; SafetyStatus get safetyStatus;@TimestampConverter() DateTime get safetyStatusUpdatedAt; bool get isActive;@TimestampConverter() DateTime get lastActiveAt;@TimestampConverter() DateTime get createdAt;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as User;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.phoneNumber, _this.phoneNumber) || other.phoneNumber == _this.phoneNumber)&&(identical(other.authProvider, _this.authProvider) || other.authProvider == _this.authProvider)&&const DeepCollectionEquality().equals(other.roles, _this.roles)&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.competencyTag, _this.competencyTag) || other.competencyTag == _this.competencyTag)&&(identical(other.safetyStatus, _this.safetyStatus) || other.safetyStatus == _this.safetyStatus)&&(identical(other.safetyStatusUpdatedAt, _this.safetyStatusUpdatedAt) || other.safetyStatusUpdatedAt == _this.safetyStatusUpdatedAt)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.lastActiveAt, _this.lastActiveAt) || other.lastActiveAt == _this.lastActiveAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as User;
  return Object.hash(runtimeType,_this.id,_this.displayName,_this.email,_this.phoneNumber,_this.authProvider,const DeepCollectionEquality().hash(_this.roles),_this.organizationId,_this.competencyTag,_this.safetyStatus,_this.safetyStatusUpdatedAt,_this.isActive,_this.lastActiveAt,_this.createdAt);
}

@override
String toString() {
  final _this = this as User;
  return 'User(id: ${_this.id}, displayName: ${_this.displayName}, email: ${_this.email}, phoneNumber: ${_this.phoneNumber}, authProvider: ${_this.authProvider}, roles: ${_this.roles}, organizationId: ${_this.organizationId}, competencyTag: ${_this.competencyTag}, safetyStatus: ${_this.safetyStatus}, safetyStatusUpdatedAt: ${_this.safetyStatusUpdatedAt}, isActive: ${_this.isActive}, lastActiveAt: ${_this.lastActiveAt}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String email, String? phoneNumber, AuthProvider authProvider, List<UserRole> roles, String? organizationId, CompetencyTag? competencyTag, SafetyStatus safetyStatus,@TimestampConverter() DateTime safetyStatusUpdatedAt, bool isActive,@TimestampConverter() DateTime lastActiveAt,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? email = null,Object? phoneNumber = freezed,Object? authProvider = null,Object? roles = null,Object? organizationId = freezed,Object? competencyTag = freezed,Object? safetyStatus = null,Object? safetyStatusUpdatedAt = null,Object? isActive = null,Object? lastActiveAt = null,Object? createdAt = null,}) {
  return _then(User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,authProvider: null == authProvider ? _self.authProvider : authProvider // ignore: cast_nullable_to_non_nullable
as AuthProvider,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<UserRole>,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,competencyTag: freezed == competencyTag ? _self.competencyTag : competencyTag // ignore: cast_nullable_to_non_nullable
as CompetencyTag?,safetyStatus: null == safetyStatus ? _self.safetyStatus : safetyStatus // ignore: cast_nullable_to_non_nullable
as SafetyStatus,safetyStatusUpdatedAt: null == safetyStatusUpdatedAt ? _self.safetyStatusUpdatedAt : safetyStatusUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String email,  String? phoneNumber,  AuthProvider authProvider,  List<UserRole> roles,  String? organizationId,  CompetencyTag? competencyTag,  SafetyStatus safetyStatus, @TimestampConverter()  DateTime safetyStatusUpdatedAt,  bool isActive, @TimestampConverter()  DateTime lastActiveAt, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.phoneNumber,_that.authProvider,_that.roles,_that.organizationId,_that.competencyTag,_that.safetyStatus,_that.safetyStatusUpdatedAt,_that.isActive,_that.lastActiveAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String email,  String? phoneNumber,  AuthProvider authProvider,  List<UserRole> roles,  String? organizationId,  CompetencyTag? competencyTag,  SafetyStatus safetyStatus, @TimestampConverter()  DateTime safetyStatusUpdatedAt,  bool isActive, @TimestampConverter()  DateTime lastActiveAt, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.id,_that.displayName,_that.email,_that.phoneNumber,_that.authProvider,_that.roles,_that.organizationId,_that.competencyTag,_that.safetyStatus,_that.safetyStatusUpdatedAt,_that.isActive,_that.lastActiveAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String email,  String? phoneNumber,  AuthProvider authProvider,  List<UserRole> roles,  String? organizationId,  CompetencyTag? competencyTag,  SafetyStatus safetyStatus, @TimestampConverter()  DateTime safetyStatusUpdatedAt,  bool isActive, @TimestampConverter()  DateTime lastActiveAt, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.phoneNumber,_that.authProvider,_that.roles,_that.organizationId,_that.competencyTag,_that.safetyStatus,_that.safetyStatusUpdatedAt,_that.isActive,_that.lastActiveAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({required this.id, required this.displayName, required this.email, this.phoneNumber, required this.authProvider,  List<UserRole> roles = const [], this.organizationId, this.competencyTag, this.safetyStatus = SafetyStatus.unknown, @TimestampConverter() required this.safetyStatusUpdatedAt, this.isActive = true, @TimestampConverter() required this.lastActiveAt, @TimestampConverter() required this.createdAt}): _roles = roles;
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String email;
@override final  String? phoneNumber;
@override final  AuthProvider authProvider;
 final  List<UserRole> _roles;
@override@JsonKey() List<UserRole> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override final  String? organizationId;
@override final  CompetencyTag? competencyTag;
@override@JsonKey() final  SafetyStatus safetyStatus;
@override@TimestampConverter() final  DateTime safetyStatusUpdatedAt;
@override@JsonKey() final  bool isActive;
@override@TimestampConverter() final  DateTime lastActiveAt;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.authProvider, authProvider) || other.authProvider == authProvider)&&const DeepCollectionEquality().equals(other.roles, _roles)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.competencyTag, competencyTag) || other.competencyTag == competencyTag)&&(identical(other.safetyStatus, safetyStatus) || other.safetyStatus == safetyStatus)&&(identical(other.safetyStatusUpdatedAt, safetyStatusUpdatedAt) || other.safetyStatusUpdatedAt == safetyStatusUpdatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,displayName,email,phoneNumber,authProvider,const DeepCollectionEquality().hash(_roles),organizationId,competencyTag,safetyStatus,safetyStatusUpdatedAt,isActive,lastActiveAt,createdAt);
}

@override
String toString() {
    return 'User(id: $id, displayName: $displayName, email: $email, phoneNumber: $phoneNumber, authProvider: $authProvider, roles: $roles, organizationId: $organizationId, competencyTag: $competencyTag, safetyStatus: $safetyStatus, safetyStatusUpdatedAt: $safetyStatusUpdatedAt, isActive: $isActive, lastActiveAt: $lastActiveAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String email, String? phoneNumber, AuthProvider authProvider, List<UserRole> roles, String? organizationId, CompetencyTag? competencyTag, SafetyStatus safetyStatus,@TimestampConverter() DateTime safetyStatusUpdatedAt, bool isActive,@TimestampConverter() DateTime lastActiveAt,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? email = null,Object? phoneNumber = freezed,Object? authProvider = null,Object? roles = null,Object? organizationId = freezed,Object? competencyTag = freezed,Object? safetyStatus = null,Object? safetyStatusUpdatedAt = null,Object? isActive = null,Object? lastActiveAt = null,Object? createdAt = null,}) {
  return _then(_User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,authProvider: null == authProvider ? _self.authProvider : authProvider // ignore: cast_nullable_to_non_nullable
as AuthProvider,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<UserRole>,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,competencyTag: freezed == competencyTag ? _self.competencyTag : competencyTag // ignore: cast_nullable_to_non_nullable
as CompetencyTag?,safetyStatus: null == safetyStatus ? _self.safetyStatus : safetyStatus // ignore: cast_nullable_to_non_nullable
as SafetyStatus,safetyStatusUpdatedAt: null == safetyStatusUpdatedAt ? _self.safetyStatusUpdatedAt : safetyStatusUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
