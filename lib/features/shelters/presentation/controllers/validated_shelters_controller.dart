import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/shelters/data/shelter_repository.dart';

/// Refuges validés affichés sur la carte, alimentés en temps réel par
/// Firestore.
///
/// Un unique flux alimente tous les markers : pas de requête par refuge.
final validatedSheltersProvider = StreamProvider<List<Shelter>>(
  (ref) => ref.watch(shelterRepositoryProvider).watchValidatedShelters(),
);
