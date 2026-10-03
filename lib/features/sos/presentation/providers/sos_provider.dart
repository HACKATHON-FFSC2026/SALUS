import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/app/di/app_dependencies.dart';
import '../../domain/usecases/cancel_sos_usecase.dart';
import '../../domain/usecases/respond_to_sos_usecase.dart';
import '../../domain/usecases/send_sos_usecase.dart';
import '../../domain/usecases/watch_sos_usecase.dart';

enum SosStatus { initial, loading, sending, success, error }

class SosState {
  const SosState({
    this.status = SosStatus.initial,
    this.errorMessage,
    this.alertId,
    this.alert,
    this.sharingLocation = false,
  });

  /// Résultat de la dernière action (envoyer / annuler).
  final SosStatus status;
  final String? errorMessage;

  /// Mon alerte en cours. Non null entre l'envoi et la résolution.
  final String? alertId;

  /// Dernier état connu de cette alerte, alimenté par le flux temps réel.
  final SOSAlert? alert;

  /// Le partage de position temps réel tourne.
  final bool sharingLocation;

  /// Une alerte existe et n'est ni résolue ni annulée.
  bool get hasActiveAlert => alertId != null && (alert?.isActive ?? true);

  SosState copyWith({
    SosStatus? status,
    String? errorMessage,
    String? alertId,
    SOSAlert? alert,
    bool? sharingLocation,
    bool clearError = false,
  }) {
    return SosState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      alertId: alertId ?? this.alertId,
      alert: alert ?? this.alert,
      sharingLocation: sharingLocation ?? this.sharingLocation,
    );
  }
}

final sendSosUseCaseProvider = Provider<SendSosUseCase>(
  (ref) => SendSosUseCase(ref.watch(sosRepositoryProvider)),
);

final cancelSosUseCaseProvider = Provider<CancelSosUseCase>(
  (ref) => CancelSosUseCase(ref.watch(sosRepositoryProvider)),
);

final watchSosUseCaseProvider = Provider<WatchSosUseCase>(
  (ref) => WatchSosUseCase(ref.watch(sosRepositoryProvider)),
);

final respondToSosUseCaseProvider = Provider<RespondToSosUseCase>(
  (ref) => RespondToSosUseCase(ref.watch(sosRepositoryProvider)),
);

/// Non autoDispose: l'alerte et le partage de position doivent survivre à la
/// navigation. Un citoyen ne doit pas voir son SOS « disparaître » en
/// sortant de la page.
final sosControllerProvider =
    NotifierProvider<SosController, SosState>(SosController.new);

/// Cadence du partage de position. Sans bridage, la précision GPS fait écrire
/// une position toutes les deux secondes.
const _locationShareThrottle = Duration(seconds: 15);

class SosController extends Notifier<SosState> {
  StreamSubscription<SOSAlert?>? _alertSub;
  StreamSubscription<Position>? _positionSub;
  DateTime? _lastSharedAt;

  @override
  SosState build() {
    ref.onDispose(_closeSubscriptions);
    // Rattrapage après un redémarrage: sans cela, un citizen qui rouvre
    // l'app en plein incident repart avec un écran SOS vide et peut envoyer
    // une seconde alerte pour la même détresse.
    Future.microtask(_resumeMyActiveAlert);
    return const SosState();
  }

  Future<void> triggerSos({
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    // Deux gardes, pas une. `hasActiveAlert` ne dépend que d'`alertId`, qui
    // n'est renseigné qu'après l'écriture : pendant l'envoi en vol il reste
    // nul et la garde passerait, créant une seconde alerte. `sending` ferme la
    // fenêtre entre le geste et l'écriture.
    if (state.status == SosStatus.sending) return;
    if (state.hasActiveAlert) {
      state = state.copyWith(
        status: SosStatus.error,
        errorMessage: 'Une alerte SOS est déjà en cours.',
      );
      return;
    }

    state = state.copyWith(status: SosStatus.sending, clearError: true);
    try {
      final alertId = await ref.read(sendSosUseCaseProvider).execute(
        distressType: distressType,
        description: description,
      );

      state = SosState(status: SosStatus.success, alertId: alertId);
      _track(alertId);
      _startSharingLocation(alertId);
    } catch (e) {
      state = state.copyWith(status: SosStatus.error, errorMessage: _message(e));
    }
  }

  /// « Je suis en sécurité ».
  Future<void> cancelSos() async {
    final alertId = state.alertId;
    if (alertId == null || state.status == SosStatus.loading) return;
    // Déjà résolue ou annulée: les règles Firestore refuseraient l'écriture,
    // autant ne pas la tenter.
    if (!state.hasActiveAlert) return;

    state = state.copyWith(status: SosStatus.loading, clearError: true);
    try {
      await ref.read(cancelSosUseCaseProvider).execute(alertId);
      // On ne force pas le statut en local: le flux le confirmera. En
      // revanche le partage de position n'a plus d'intérêt.
      _stopSharingLocation();
      state = state.copyWith(status: SosStatus.success);
    } catch (e) {
      state = state.copyWith(status: SosStatus.error, errorMessage: _message(e));
    }
  }

  void resetFeedback() =>
      state = state.copyWith(status: SosStatus.initial, clearError: true);

  Future<void> _resumeMyActiveAlert() async {
    if (state.alertId != null) return;
    try {
      final mine = await ref
          .read(sosRepositoryProvider)
          .watchMyActiveSosAlerts()
          .first;
      if (mine.isEmpty) return;

      final alert = mine.first;
      state = state.copyWith(alertId: alert.id, alert: alert);
      _track(alert.id);
      _startSharingLocation(alert.id);
    } catch (e) {
      // Rattrapage opportuniste: son échec ne doit rien casser.
      Log.warning('Impossible de restaurer l alerte SOS en cours: $e');
    }
  }

  void _track(String alertId) {
    _alertSub?.cancel();
    _alertSub = ref.read(watchSosUseCaseProvider).execute(alertId).listen(
      (alert) {
        if (alert == null) {
          // Document disparu ou devenu illisible: on se désabonne plutôt que
          // de laisser une alerte « en cours » qui n'existe plus.
          _closeSubscriptions();
          state = const SosState();
          return;
        }
        if (!alert.isActive) _stopSharingLocation();
        state = state.copyWith(alert: alert);
      },
      onError: (Object e, StackTrace s) {
        Log.error('Suivi SOS interrompu ($alertId)', e, s);
      },
    );
  }

  /// Partage la position tant que l'alerte est active et que l'app tourne.
  /// Coupe automatiquement à la résolution ou à l'annulation.
  void _startSharingLocation(String alertId) {
    if (_positionSub != null) return;
    try {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(
        (position) => _shareLocation(alertId, position),
        onError: (Object e, StackTrace s) {
          Log.error('Partage de position indisponible', e, s);
          _positionSub = null;
        },
        cancelOnError: true,
      );
      state = state.copyWith(sharingLocation: true);
    } catch (e) {
      // Sans GPS l'alerte reste valide: seul le suivi est perdu.
      Log.warning('Partage de position non démarré: $e');
    }
  }

  void _shareLocation(String alertId, Position position) {
    final now = DateTime.now();
    final last = _lastSharedAt;
    if (last != null && now.difference(last) < _locationShareThrottle) return;
    _lastSharedAt = now;

    ref
        .read(sosRepositoryProvider)
        .shareLocation(
          alertId: alertId,
          latitude: position.latitude,
          longitude: position.longitude,
        )
        .catchError((Object e) => Log.warning('Position non partagée: $e'));
  }

  void _stopSharingLocation() {
    _closeSubscriptions(locationOnly: true);
    if (state.sharingLocation) {
      state = state.copyWith(sharingLocation: false);
    }
  }

  /// Nettoyage sans écriture d'état: appelé aussi depuis `ref.onDispose`, où
  /// Riverpod interdit de toucher `state`.
  void _closeSubscriptions({bool locationOnly = false}) {
    if (!locationOnly) _alertSub?.cancel();
    _alertSub = null;
    _positionSub?.cancel();
    _positionSub = null;
    _lastSharedAt = null;
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');
}
