import 'package:salus/core/entities/shelter_entity.dart';

/// Règles métier pures (aucune dépendance Firebase).
abstract final class ShelterRules {
  /// Seuil « presque complet » (80 %). À aligner avec la carte si elle en a un.
  static const almostFullThreshold = 0.8;

  static int clampOccupancy(int value, int capacity) =>
      value.clamp(0, capacity);

  /// - fermé reste fermé ;
  /// - « complet » demandé manuellement est respecté ;
  /// - sinon le statut est déduit du remplissage.
  static ShelterStatus statusFor({
    required ShelterStatus requested,
    required int capacity,
    required int occupancy,
  }) {
    if (requested == ShelterStatus.closed) return ShelterStatus.closed;
    if (requested == ShelterStatus.full) return ShelterStatus.full;
    if (occupancy >= capacity) return ShelterStatus.full;
    if (capacity > 0 && occupancy / capacity >= almostFullThreshold) {
      return ShelterStatus.almostFull;
    }
    return ShelterStatus.open;
  }
}

extension ShelterOccupancy on Shelter {
  int get available =>
      (capacityTotal - capacityOccupied).clamp(0, capacityTotal);
  double get fillRate =>
      capacityTotal == 0 ? 0 : (capacityOccupied / capacityTotal).clamp(0, 1);
}
