import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/features/alerts/data/datasources/alerts_remote_datasource.dart';
import 'package:salus/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:salus/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:salus/features/alerts/domain/usecases/manage_sos_alerts_usecase.dart';

/// Provider d'accès à la source de données distante des alertes
final alertsDataSourceProvider = Provider<IAlertsRemoteDataSource>((ref) {
  return AlertsRemoteDataSourceImpl();
});

final alertsRepositoryProvider = Provider<IAlertsRepository>((ref) {
  return AlertsRepositoryImpl(ref.watch(alertsDataSourceProvider));
});

final manageSosAlertsUseCaseProvider = Provider<ManageSosAlertsUseCase>((ref) {
  return ManageSosAlertsUseCase(ref.watch(alertsRepositoryProvider));
});

/// StreamProvider : Écoute en temps réel l'état d'un SOS spécifique par son ID (Tâche 12)
final sosAlertStreamProvider = StreamProvider.family<SOSAlert?, String>((
  ref,
  alertId,
) {
  return ref.watch(manageSosAlertsUseCaseProvider).watchAlert(alertId);
});

/// StreamProvider : Écoute en temps réel TOUTES les alertes SOS actives à proximité (Tâche 14)
final nearbyActiveSosStreamProvider = StreamProvider<List<SOSAlert>>((ref) {
  return ref.watch(manageSosAlertsUseCaseProvider).watchActiveAlerts();
});

/// StateNotifierProvider : Controller central pour les actions asynchrones (Tâches 11, 13, 15)
final alertsControllerProvider = AsyncNotifierProvider<AlertsController, void>(
  AlertsController.new,
);

class AlertsController extends AsyncNotifier<void> {
  late ManageSosAlertsUseCase _useCase;

  @override
  FutureOr<void> build() {
    _useCase = ref.watch(manageSosAlertsUseCaseProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Tâche 11 : Créer / Déclencher une alerte SOS
  Future<void> createSos({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    await _run(
      () => _useCase.create(
        latitude: latitude,
        longitude: longitude,
        distressType: distressType,
        description: description,
      ),
    );
  }

  /// Tâche 13 : Annuler une alerte SOS ("Je suis en sécurité")
  Future<void> cancelSos(String alertId) async {
    await _run(() => _useCase.cancel(alertId));
  }

  /// Tâche 15 : Répondre à une alerte SOS (Se déclarer intervenant)
  Future<void> respondToSos(String alertId) async {
    await _run(() => _useCase.respond(alertId));
  }

  /// Marquer une alerte SOS comme résolue
  Future<void> resolveSos(String alertId, {String? resolutionType, String? resolutionNote}) async {
    await _run(() => _useCase.resolve(alertId, resolutionType: resolutionType, resolutionNote: resolutionNote));
  }
}
