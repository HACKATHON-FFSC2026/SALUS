import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/utils/log.dart';
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

/// Demande la permission de localisation, une fois par session si possible.
///
/// À appeler en entrant sur la page SOS, jamais depuis le geste d'envoi :
/// demander une permission système pendant qu'une personne signale une
/// détresse lui fait perdre du temps et aboutit trop souvent à un refus.
Future<void> requestLocationPermission() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    if (await Geolocator.checkPermission() != LocationPermission.denied) return;
    await Geolocator.requestPermission();
  } catch (e) {
    // Une indisponibilité de la plateforme ne doit pas empêcher d'afficher la
    // page: l'envoi signalera l'erreur au bon moment.
    Log.warning('Permission de localisation non demandée: $e');
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