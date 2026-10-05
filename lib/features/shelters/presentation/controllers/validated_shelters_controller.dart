import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/core/utils/log.dart';

/// Refuges validés affichés sur la carte, alimentés en temps réel par
/// Firestore.
///
/// Un unique flux alimente tous les markers : pas de requête par refuge.
final validatedSheltersProvider = StreamProvider<List<Shelter>>(
  (ref) => ref
      .watch(shelterRepositoryProvider)
      .watchValidatedShelters()
      .handleError((Object error, StackTrace stackTrace) {
        Log.error('Échec du chargement des refuges validés', error, stackTrace);
        throw error;
      }),
);

/// Tous les statuts de validation pour la liste de refuges. La carte utilise
/// toujours [validatedSheltersProvider] afin de ne montrer que les refuges
/// validés.
final allSheltersProvider = StreamProvider<List<Shelter>>(
  (ref) => ref.watch(shelterRepositoryProvider).watchAllShelters().handleError((
    Object error,
    StackTrace stackTrace,
  ) {
    Log.error('Échec du chargement de la liste des refuges', error, stackTrace);
    throw error;
  }),
);
