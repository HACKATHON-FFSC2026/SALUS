// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_response_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HelpResponse _$HelpResponseFromJson(Map<String, dynamic> json) =>
    _HelpResponse(
      id: json['id'] as String,
      sosAlertId: json['sosAlertId'] as String,
      responderId: json['responderId'] as String,
      responseType: $enumDecode(_$ResponseTypeEnumMap, json['responseType']),
      message: json['message'] as String?,
      status:
          $enumDecodeNullable(_$HelpResponseStatusEnumMap, json['status']) ??
          HelpResponseStatus.offered,
      createdAt: const TimestampConverter().fromJson(
        json['createdAt'] as Timestamp,
      ),
      updatedAt: const TimestampConverter().fromJson(
        json['updatedAt'] as Timestamp,
      ),
    );

Map<String, dynamic> _$HelpResponseToJson(_HelpResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sosAlertId': instance.sosAlertId,
      'responderId': instance.responderId,
      'responseType': _$ResponseTypeEnumMap[instance.responseType]!,
      'message': instance.message,
      'status': _$HelpResponseStatusEnumMap[instance.status]!,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };

const _$ResponseTypeEnumMap = {
  ResponseType.comingInPerson: 'comingInPerson',
  ResponseType.textAdvice: 'textAdvice',
};

const _$HelpResponseStatusEnumMap = {
  HelpResponseStatus.offered: 'offered',
  HelpResponseStatus.enRoute: 'enRoute',
  HelpResponseStatus.arrived: 'arrived',
  HelpResponseStatus.cancelled: 'cancelled',
};
