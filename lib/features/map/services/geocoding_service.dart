import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/core/sources/remote_client.dart';
import 'package:salus/features/map/domain/models/geocoding_result.dart';

/// Recherche de lieu et geocoding inverse.
///
/// Aucune librairie de geocoding n'était présente dans le projet : on appelle
/// l'API publique Nominatim (OpenStreetMap) avec le client Dio existant
/// (`remoteClientProvider`), donc sans nouvelle dépendance.
class GeocodingService {
  GeocodingService(this._dio);

  static const baseUrl = 'https://nominatim.openstreetmap.org';

  /// ponytail: Nominatim exige un User-Agent identifiable et limite à ~1 req/s.
  /// Passer par un proxy (API_BASE_URL du .env) si l'usage devient intensif.
  static const userAgent = 'salus-app/0.1.0 (SALUS FlutterFire Summer Camp)';

  static const maxResults = 5;

  final Dio _dio;

  /// Recherche des lieux correspondant à [query], ex. « Mahamasina ».
  Future<List<GeocodingResult>> search(String query) async {
    final response = await _dio.get<dynamic>(
      '$baseUrl/search',
      queryParameters: {'q': query, 'format': 'jsonv2', 'limit': maxResults},
      options: Options(headers: _headers),
    );

    final data = response.data;
    if (data is! List) return const [];
    return parseSearchResults(data);
  }

  /// Adresse lisible correspondant à [point], `null` si introuvable.
  Future<String?> reverse(LatLng point) async {
    final response = await _dio.get<dynamic>(
      '$baseUrl/reverse',
      queryParameters: {
        'lat': point.latitude,
        'lon': point.longitude,
        'format': 'jsonv2',
        'zoom': 18,
      },
      options: Options(headers: _headers),
    );

    final data = response.data;
    if (data is! Map) return null;
    return parseReverseLabel(Map<String, dynamic>.from(data));
  }

  static const _headers = {
    'User-Agent': userAgent,
    'Accept': 'application/json',
  };

  /// Convertit la réponse de `/search` en résultats exploitables.
  static List<GeocodingResult> parseSearchResults(List<dynamic> data) {
    return data
        .whereType<Map>()
        .map(
          (raw) =>
              GeocodingResult.fromSearchJson(Map<String, dynamic>.from(raw)),
        )
        .whereType<GeocodingResult>()
        .toList();
  }

  /// Extrait l'adresse lisible d'une réponse de `/reverse`.
  static String? parseReverseLabel(Map<String, dynamic>? data) {
    final label = data?['display_name'];
    if (label is! String || label.isEmpty) return null;
    return label;
  }
}

final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => GeocodingService(ref.watch(remoteClientProvider)),
);
