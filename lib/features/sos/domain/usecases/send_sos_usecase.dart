import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import '../repositories/sos_repository.dart';

class SendSosUseCase {
  final ISosRepository _repository;

  SendSosUseCase(this._repository);

  Future<void> execute({
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    // 1. Vérification de l'activation du service de géolocalisation
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Le service de géolocalisation est désactivé sur votre appareil.');
    }

    // 2. Vérification et demande des permissions GPS
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Les permissions de localisation sont bloquées dans vos paramètres.');
    }

    // 3. Récupération des coordonnées GPS
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // 4. Envoi du SOS via le repository
    await _repository.sendSos(
      latitude: position.latitude,
      longitude: position.longitude,
      distressType: distressType,
      description: description,
    );
  }
}