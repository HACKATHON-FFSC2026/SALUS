import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/shelters/data/shelter_repository.dart';
import 'package:salus/features/shelters/domain/models/shelter_creation_state.dart';

/// Uid de l'utilisateur connecté (`null` si personne ou un invité).
/// Exposé en provider pour pouvoir être surchargé dans les tests.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authRepositoryProvider).currentUserId,
);

final shelterCreationControllerProvider =
    StateNotifierProvider<ShelterCreationController, ShelterCreationState>((
      ref,
    ) {
      return ShelterCreationController(
        ref.watch(shelterRepositoryProvider),
        ref.watch(currentUserIdProvider),
      );
    });

/// Création d'une fiche refuge : contrôle de l'utilisateur connecté, valeurs
/// par défaut du MVP (occupation 0, validation en attente, statut ouvert) puis
/// persistance via le repository.
class ShelterCreationController extends StateNotifier<ShelterCreationState> {
  ShelterCreationController(this._repository, this._userId)
    : super(const ShelterCreationState());

  final ShelterRepository _repository;
  final String? _userId;

  /// Repart d'un état vierge (nouvelle ouverture du formulaire).
  void reset() => state = const ShelterCreationState();

  Future<void> createShelter({
    required String name,
    required String address,
    required GeoPoint location,
    required int capacityTotal,
    ShelterResources resources = const ShelterResources(),
    List<String> photos = const [],
  }) async {
    // Protection contre les soumissions multiples.
    if (state.isSubmitting) return;

    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      state = const ShelterCreationState(
        status: ShelterCreationStatus.error,
        errorMessage: 'Vous devez être connecté pour créer un refuge.',
      );
      return;
    }

    state = const ShelterCreationState(status: ShelterCreationStatus.loading);

    try {
      final now = DateTime.now();
      final created = await _repository.createShelter(
        Shelter(
          id: '',
          name: name.trim(),
          location: location,
          address: address.trim(),
          capacityTotal: capacityTotal,
          capacityOccupied: 0,
          status: ShelterStatus.open,
          resources: resources,
          photos: photos,
          createdBy: userId,
          validationStatus: ValidationStatus.pending,
          unsafeReportsCount: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      state = ShelterCreationState(
        status: ShelterCreationStatus.success,
        shelter: created,
      );
    } catch (e, s) {
      Log.error('Création du refuge impossible', e, s);
      state = const ShelterCreationState(
        status: ShelterCreationStatus.error,
        errorMessage:
            'Impossible de créer le refuge. Vérifiez votre connexion puis réessayez.',
      );
    }
  }
}
