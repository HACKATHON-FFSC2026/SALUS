import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/map/domain/location.dart';

class AssistantApi {
  AssistantApi(this._dio, this._baseUrl, this._auth);

  final Dio _dio;
  final String _baseUrl;
  final FirebaseAuth _auth;

  Future<AssistantReply> chat({
    required String message,
    required List<AssistantTurn> history,
    GeoPoint? location,
  }) async {
    final token = await _idToken();
    final url = _endpoint('/v1/assistant/chat');
    Log.info(
      'Copilote chat → POST $url '
      '(history=${history.length}, location=${location != null})',
    );
    try {
      final response = await _dio.post<Object?>(
        url,
        data: {
          'message': message,
          'history': [for (final turn in history) turn.toJson()],
          if (location != null)
            'location': {
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      Log.info('Copilote chat ← HTTP ${response.statusCode}');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AssistantApiException('Réponse du service invalide.');
      }
      return AssistantReply.fromJson(data);
    } on DioException catch (error) {
      Log.error(
        'Copilote chat ← échec type=${error.type.name} '
        'status=${error.response?.statusCode}',
        error,
      );
      throw AssistantApiException(_errorMessage(error));
    }
  }

  Future<String> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      Log.warning('Copilote: aucun utilisateur Firebase connecté (invité ?)');
      throw const AssistantApiException(
        'Connectez-vous pour utiliser le copilote.',
      );
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      Log.warning('Copilote: getIdToken() a renvoyé un jeton vide');
      throw const AssistantApiException('Session invalide. Reconnectez-vous.');
    }
    // Length only: never log the token value.
    Log.info('Copilote: jeton Firebase obtenu (len=${token.length})');
    return token;
  }

  String _endpoint(String path) {
    if (_baseUrl.trim().isEmpty) {
      throw const AssistantApiException(
        'Le service du copilote n’est pas configuré sur cette version.',
      );
    }
    return '${_baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path';
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Le service met trop de temps à répondre. Réessayez.',
      DioExceptionType.connectionError =>
        'Connexion impossible. Vérifiez votre réseau.',
      _ =>
        'Le copilote est momentanément indisponible. Consultez le guide d’urgence.',
    };
  }
}

class AssistantTurn {
  const AssistantTurn(this.role, this.content);

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AssistantReply {
  const AssistantReply({
    required this.answer,
    required this.riskDataAvailable,
    this.riskSummary,
    this.shelter,
    this.sosRequested = false,
  });

  final String answer;
  final bool riskDataAvailable;
  final String? riskSummary;
  final AssistantShelter? shelter;

  /// L'utilisateur a formulé une détresse explicite : l'app doit déclencher un SOS.
  final bool sosRequested;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    final shelter = json['shelter'];
    return AssistantReply(
      answer: json['answer'] as String? ?? '',
      riskDataAvailable: json['riskDataAvailable'] as bool? ?? false,
      riskSummary: json['riskSummary'] as String?,
      shelter: shelter is Map<String, dynamic>
          ? AssistantShelter.fromJson(shelter)
          : null,
      sosRequested: json['sosRequested'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'answer': answer,
    'riskDataAvailable': riskDataAvailable,
    if (riskSummary != null) 'riskSummary': riskSummary,
    if (shelter != null) 'shelter': shelter!.toJson(),
    'sosRequested': sosRequested,
  };
}

class AssistantShelter {
  const AssistantShelter({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.status,
    required this.availablePlaces,
    this.address = '',
    this.resources = const [],
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final String status;
  final int availablePlaces;
  final List<String> resources;

  factory AssistantShelter.fromJson(Map<String, dynamic> json) =>
      AssistantShelter(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Refuge',
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        distanceMeters: json['distanceMeters'] as int? ?? 0,
        status: json['status'] as String? ?? '',
        availablePlaces: json['availablePlaces'] as int? ?? 0,
        resources: (json['resources'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'distanceMeters': distanceMeters,
    'status': status,
    'availablePlaces': availablePlaces,
    'resources': resources,
  };
}

class AssistantApiException implements Exception {
  const AssistantApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
