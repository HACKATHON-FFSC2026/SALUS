import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:salus/features/sos/domain/entities/help_response.dart';
import 'package:salus/features/sos/domain/entities/responder_location.dart';
import 'package:salus/features/sos/domain/usecases/offer_help_usecase.dart';
import 'package:salus/features/sos/domain/usecases/send_sos_usecase.dart';

final offerHelpUseCaseProvider = Provider<OfferHelpUseCase>(
  (ref) => OfferHelpUseCase(ref.watch(sosRepositoryProvider)),
);

final setHelpStatusUseCaseProvider = Provider<SetHelpStatusUseCase>(
  (ref) => SetHelpStatusUseCase(ref.watch(sosRepositoryProvider)),
);

/// IntervenantsDeclare sur une alerte, pour la victime.
///
/// Le compte ne vient pas de `responderIds`: ce registre est figé par les
/// règles, qui n'autorisent que l'ajout. Quelqu'un qui s'est retracte y reste
/// pour l'audit, mais ne doit plus etre compte ni affiche comme en route.
final respondersProvider = StreamProvider.family
    .autoDispose<List<HelpResponse>, String>((ref, alertId) {
      return ref
          .watch(sosRepositoryProvider)
          .watchHelpResponses(alertId)
          .map(
            (responses) =>
                responses.where((r) => r.isActive).toList(growable: false),
          );
    });

/// Positions connues des intervenants, indexées par uid.
final responderLocationsProvider = StreamProvider.family
    .autoDispose<Map<String, ResponderLocation>, String>((ref, alertId) {
      return ref.watch(sosRepositoryProvider).watchResponderLocations(
        alertId,
      ).map((locations) => {for (final l in locations) l.userId: l});
    });

enum ResponderStatus { idle, sharing, arrived, cancelled, failure }

class ResponderState {
  const ResponderState({
    this.status = ResponderStatus.idle,
    this.isSharingLocation = false,
    this.errorMessage,
  });

  final ResponderStatus status;

  /// Vrai quand la position de l'intervenant remonte vers la victime.
  final bool isSharingLocation;

  final String? errorMessage;

  ResponderState copyWith({
    ResponderStatus? status,
    bool? isSharingLocation,
    String? errorMessage,
  }) {
    return ResponderState(
      status: status ?? this.status,
      isSharingLocation: isSharingLocation ?? this.isSharingLocation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Suivi du côté intervenant, symétrique de [SosController] côté victime.
class ResponderController extends Notifier<ResponderState> {
  /// 15 s entre deux écritures: assez fin pour que la victime suive un
  /// déplacement, assez lâche pour ne pas brûler le quota d'écriture.
  static const _throttle = Duration(seconds: 15);

  StreamSubscription<Position>? _positionSub;
  DateTime? _lastSharedAt;
  String? _alertId;

  @override
  ResponderState build() {
    // Libère le flux GPS quand plus personne n'observe le contrôleur, pas
    // seulement au rebuild.
    ref.onDispose(_closePositionStream);
    return const ResponderState();
  }

  /// Demande la permission puis publie la position en continu.
  ///
  /// Ne lève rien si le GPS est indisponible: l'intervenant doit pouvoir
  /// suivre les consignes et l'itinéraire même sans être localisé.
  Future<void> startSharing({required String alertId}) async {
    _alertId = alertId;
    await requestLocationPermission();

    if (!await Geolocator.isLocationServiceEnabled()) {
      state = state.copyWith(
        status: ResponderStatus.sharing,
        errorMessage: 'Géolocalisation désactivée: la victime ne voit pas votre position.',
      );
      return;
    }

    try {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(
        _publish,
        onError: (Object e, StackTrace s) {
          Log.error('Suivi intervenant interrompu', e, s);
          _positionSub = null;
          state = state.copyWith(
            status: ResponderStatus.sharing,
            isSharingLocation: false,
          );
        },
        cancelOnError: true,
      );
      state = state.copyWith(
        status: ResponderStatus.sharing,
        isSharingLocation: true,
      );
    } catch (e) {
      Log.warning('Suivi intervenant non démarré: $e');
      state = state.copyWith(
        status: ResponderStatus.sharing,
        errorMessage: 'Position indisponible: indiquez à la victime votre arrivée.',
      );
    }
  }

  void _publish(Position position) {
    final alertId = _alertId;
    if (alertId == null) return;
    final now = DateTime.now();
    final last = _lastSharedAt;
    if (last != null && now.difference(last) < _throttle) return;
    _lastSharedAt = now;

    ref
        .read(sosRepositoryProvider)
        .shareResponderLocation(
          alertId: alertId,
          latitude: position.latitude,
          longitude: position.longitude,
        )
        .catchError((Object e) => Log.warning('Position non partagée: $e'));
  }

  /// « Je suis arrivé sur place ». C'est aussi le seul moyen, hors portail web,
  /// de faire passer une alerte en cours.
  Future<void> markArrived({required String responseId}) async {
    await _setStatus(responseId, HelpResponseStatus.arrived);
  }

  /// « Je ne peux plus venir ». La victime ne compte plus cet intervenant.
  Future<void> withdraw({required String responseId}) async {
    await _setStatus(responseId, HelpResponseStatus.cancelled);
    _closePositionStream();
    final alertId = _alertId;
    if (alertId == null) return;
    await ref
        .read(sosRepositoryProvider)
        .stopResponderLocation(alertId)
        .catchError((Object e) => Log.warning('Arrêt du partage impossible: $e'));
  }

  Future<void> _setStatus(String responseId, HelpResponseStatus status) async {
    try {
      await ref
          .read(setHelpStatusUseCaseProvider)
          .execute(responseId: responseId, status: status);
      state = state.copyWith(
        status: status == HelpResponseStatus.cancelled
            ? ResponderStatus.cancelled
            : ResponderStatus.arrived,
        isSharingLocation: status == HelpResponseStatus.cancelled
            ? false
            : state.isSharingLocation,
      );
    } catch (e) {
      Log.error('Suivi intervenant non mis à jour', e);
      state = state.copyWith(
        status: ResponderStatus.failure,
        errorMessage: 'Mise à jour impossible: $e',
      );
    }
  }

  void _closePositionStream() {
    _positionSub?.cancel();
    _positionSub = null;
    _lastSharedAt = null;
  }
}

final responderControllerProvider =
    NotifierProvider<ResponderController, ResponderState>(
      ResponderController.new,
    );

/// Distance en mètres entre la victime et un intervenant, pour l'affichage.
/// `null` si l'une des positions est inconnue: on n'invente pas une distance.
double? distanceInMeters({
  required SOSAlert alert,
  required ResponderLocation? location,
}) {
  if (location == null) return null;
  const earthRadiusKm = 6371.0;
  const toRad = 3.141592653589793 / 180;
  final dLat = (location.latitude - alert.location.latitude) * toRad;
  final dLon = (location.longitude - alert.location.longitude) * toRad;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(alert.location.latitude * toRad) *
          math.cos(location.latitude * toRad) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusKm * math.atan2(math.sqrt(h), math.sqrt(1 - h)) * 1000;
}
