import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// ponytail: passthrough converters — Firestore renvoie déjà Timestamp/GeoPoint,
// json_serializable a juste besoin qu'on le lui dise.

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp json) => json.toDate();

  @override
  Timestamp toJson(DateTime object) => Timestamp.fromDate(object);
}

class GeoPointConverter implements JsonConverter<GeoPoint, GeoPoint> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(GeoPoint json) => json;

  @override
  GeoPoint toJson(GeoPoint object) => object;
}

class GeoPointListConverter
    implements JsonConverter<List<GeoPoint>, List<dynamic>> {
  const GeoPointListConverter();

  @override
  List<GeoPoint> fromJson(List<dynamic> json) => json.cast<GeoPoint>();

  @override
  List<dynamic> toJson(List<GeoPoint> object) => object;
}
