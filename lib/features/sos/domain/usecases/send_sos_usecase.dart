import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import '../repositories/sos_repository.dart';

class SendSosUseCase {
  SendSosUseCase(this._repository);

  final ISosRepository _repository;

  /// Retourne l'identifiant de l'alerte créée.
  Future<String> execute({
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    final position = await currentPosition();

    return _repository.sendSos(
      latitude: position.latitude,
      longitude: position.longitude,
      distressType: distressType,
      description: description,
    );
  }
}

/// Position GPS de l'utilisateur, permission obtenue au passage.
///
/// Partagée par l'envoi et le partage de position temps réel.
Future<Position> currentPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception(
      'La géolocalisation est désactivée sur votre appareil.',
    );
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'La localisation est bloquée. Activez-la dans vos paramètres.',
    );
  }
  if (permission == LocationPermission.denied) {
    throw Exception('Permission de localisation refusée.');
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}