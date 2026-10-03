import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

class ElevationApiService {
  final Dio _dio;
  ElevationApiService(this._dio);

  /// Open-Meteo : 100 coordonnées maximum par requête.
  Future<List<double>> fetchElevations(List<GeoPoint> points) async {
    assert(points.length <= 100);
    final res = await _dio.get<dynamic>(
      'https://api.open-meteo.com/v1/elevation',
      queryParameters: {
        'latitude': points.map((p) => p.latitude.toStringAsFixed(5)).join(','),
        'longitude': points.map((p) => p.longitude.toStringAsFixed(5)).join(','),
      },
    );
    final list = (res.data['elevation'] as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    if (list.length != points.length) {
      throw StateError('Réponse altitude incomplète');
    }
    return list;
  }
}