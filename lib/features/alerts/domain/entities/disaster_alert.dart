import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salus/core/entities/zone_entity.dart';
 
part 'disaster_alert.freezed.dart';
 
/// Alerte de prévention personnalisée pour l'utilisateur.
/// L'état "lu / non lu" n'est volontairement PAS ici : il appartient au
/// repository (il dépend de l'appareil, pas de la catastrophe).
@freezed
abstract class DisasterAlert with _$DisasterAlert {
  const factory DisasterAlert({
    /// Stable : `<zoneId>-<severity>`. Un changement de niveau (orange -> rouge)
    /// produit donc une NOUVELLE alerte, une simple mise à jour de position non.
    required String id,
    required String zoneId,
    required DisasterType disasterType,
    Severity? severity,
    required String title,
    required String message,
    required double distanceKm,
    required double bearingDeg,
    required bool approaching,
    required bool userInsideZone,
    required DateTime createdAt,
  }) = _DisasterAlert;
}
 