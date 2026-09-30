import 'package:salus/core/entities/entities.dart';

/// Cycle de vie d'une soumission du formulaire de création de refuge.
enum ShelterCreationStatus { idle, loading, success, error }

/// État du formulaire de création d'un refuge.
class ShelterCreationState {
  final ShelterCreationStatus status;
  final Shelter? shelter;
  final String? errorMessage;

  const ShelterCreationState({
    this.status = ShelterCreationStatus.idle,
    this.shelter,
    this.errorMessage,
  });

  bool get isSubmitting => status == ShelterCreationStatus.loading;
}
