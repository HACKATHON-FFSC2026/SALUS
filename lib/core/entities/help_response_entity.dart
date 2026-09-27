import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/utils/firestore_converters.dart';

part 'help_response_entity.freezed.dart';
part 'help_response_entity.g.dart';

enum ResponseType { comingInPerson, textAdvice }

enum HelpResponseStatus { offered, enRoute, arrived, cancelled }

@freezed
abstract class HelpResponse with _$HelpResponse {
  const factory HelpResponse({
    required String id,
    required String sosAlertId,
    required String responderId,
    required ResponseType responseType,
    String? message,
    @Default(HelpResponseStatus.offered) HelpResponseStatus status,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _HelpResponse;

  factory HelpResponse.fromJson(Map<String, Object?> json) =>
      _$HelpResponseFromJson(json);
}
