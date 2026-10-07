import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/sos/presentation/providers/sos_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceSosSetupChoice { loading, needsPrompt, postponed, accepted }

@immutable
class VoiceSosState {
  const VoiceSosState({
    this.isListening = false,
    this.isLoadingModel = false,
    this.setupProgress,
    this.isPaused = false,
    this.setupChoice = VoiceSosSetupChoice.loading,
    this.error,
  });

  final bool isListening;
  final bool isLoadingModel;
  final double? setupProgress;
  final bool isPaused;
  final VoiceSosSetupChoice setupChoice;
  final String? error;

  VoiceSosState copyWith({
    bool? isListening,
    bool? isLoadingModel,
    double? setupProgress,
    bool? isPaused,
    VoiceSosSetupChoice? setupChoice,
    String? error,
    bool clearError = false,
    bool clearSetupProgress = false,
  }) => VoiceSosState(
    isListening: isListening ?? this.isListening,
    isLoadingModel: isLoadingModel ?? this.isLoadingModel,
    setupProgress: clearSetupProgress
        ? null
        : setupProgress ?? this.setupProgress,
    isPaused: isPaused ?? this.isPaused,
    setupChoice: setupChoice ?? this.setupChoice,
    error: clearError ? null : error ?? this.error,
  );
}

final voiceSosProvider = NotifierProvider<VoiceSosController, VoiceSosState>(
  VoiceSosController.new,
);

class VoiceSosController extends Notifier<VoiceSosState> {
  static const _setupPreferenceKey = 'voice_sos_setup_choice';
  static const _methodChannel = MethodChannel('salus/vosk');
  static const _eventChannel = EventChannel('salus/vosk/events');

  StreamSubscription<dynamic>? _eventSubscription;
  bool _nativeReady = false;
  bool _wanted = false;
  bool _starting = false;

  @override
  VoiceSosState build() {
    ref.onDispose(() => unawaited(_disposeResources()));
    unawaited(_loadSetupChoice());
    return const VoiceSosState();
  }

  Future<void> _loadSetupChoice() async {
    try {
      final choice = (await SharedPreferences.getInstance()).getInt(
        _setupPreferenceKey,
      );
      state = state.copyWith(
        setupChoice: switch (choice) {
          1 => VoiceSosSetupChoice.postponed,
          2 => VoiceSosSetupChoice.accepted,
          _ => VoiceSosSetupChoice.needsPrompt,
        },
      );
    } catch (_) {
      state = state.copyWith(setupChoice: VoiceSosSetupChoice.needsPrompt);
    }
  }

  Future<void> acceptVoiceSosSetup() async {
    try {
      await (await SharedPreferences.getInstance()).setInt(
        _setupPreferenceKey,
        2,
      );
    } catch (_) {}
    state = state.copyWith(setupChoice: VoiceSosSetupChoice.accepted);
    await start();
  }

  Future<void> postponeVoiceSosSetup() async {
    try {
      await (await SharedPreferences.getInstance()).setInt(
        _setupPreferenceKey,
        1,
      );
    } catch (_) {}
    state = state.copyWith(setupChoice: VoiceSosSetupChoice.postponed);
    await stop();
  }

  Future<void> start() async {
    if (state.setupChoice != VoiceSosSetupChoice.accepted || state.isPaused) {
      return;
    }
    _wanted = true;
    if (_starting || state.isListening) return;
    _starting = true;
    state = state.copyWith(clearError: true);
    try {
      if (!await Permission.microphone.request().isGranted) {
        throw StateError('Permission microphone refusée.');
      }

      if (!_nativeReady) await _loadModel();
      if (!_wanted) return;

      final started = await _methodChannel.invokeMethod<bool>('start');
      if (!_wanted) {
        await _stopNative();
        return;
      }
      if (started != true) throw StateError('Vosk ne démarre pas le micro.');
      state = state.copyWith(isListening: true, isLoadingModel: false);
    } catch (error, stack) {
      final wasWanted = _wanted;
      _wanted = false;
      Log.error('Écoute vocale indisponible', error, stack);
      if (wasWanted) {
        state = state.copyWith(
          isListening: false,
          isLoadingModel: false,
          error: 'Écoute vocale indisponible : $error',
        );
      }
    } finally {
      _starting = false;
      if (_wanted &&
          !state.isListening &&
          !state.isPaused &&
          state.error == null) {
        unawaited(start());
      }
    }
  }

  Future<void> _loadModel() async {
    _eventSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: _onRecognitionError,
    );
    state = state.copyWith(isLoadingModel: true, clearSetupProgress: true);
    await _methodChannel.invokeMethod<void>('initialize', {
      'modelAsset': 'models/vosk-model-small-fr-0.22.zip',
    });
    _nativeReady = true;
  }

  void _onNativeEvent(dynamic event) {
    if (event is! Map) return;
    if (event['type'] == 'modelProgress') {
      final progress = event['progress'];
      if (_wanted && progress is num) {
        state = state.copyWith(setupProgress: progress.toDouble());
      }
      return;
    }
    if (!_wanted) return;
    if (event['type'] == 'error') {
      _onRecognitionError(StateError(event['message']?.toString() ?? 'Vosk'));
      return;
    }
    final json = event['json'];
    if (json is String) _onRecognition(json);
  }

  void _onRecognition(String json) {
    if (!_wanted) return;
    try {
      final result = jsonDecode(json) as Map<String, dynamic>;
      final words = (result['text'] ?? result['partial'] ?? '') as String;
      if (matchesSosVoicePhrase(words)) _triggerSos();
    } catch (_) {
      // Ignore malformed interim results; the recognizer continues streaming.
    }
  }

  void _onRecognitionError(Object error) {
    if (!_wanted) return;
    _wanted = false;
    unawaited(_stopNative());
    state = state.copyWith(
      isListening: false,
      error: 'Reconnaissance vocale interrompue. Touchez pour réessayer.',
    );
  }

  void _triggerSos() {
    if (!_wanted) return;
    _wanted = false;
    state = state.copyWith(isListening: false, clearError: true);
    unawaited(_stopNative());
    unawaited(
      ref
          .read(sosControllerProvider.notifier)
          .triggerSos(distressType: DistressType.other),
    );
  }

  Future<void> stop() async {
    _wanted = false;
    await _stopNative();
    final setupInProgress = _starting && state.isLoadingModel;
    state = state.copyWith(
      isListening: false,
      isLoadingModel: setupInProgress,
      clearSetupProgress: !setupInProgress,
    );
  }

  Future<void> pause() async {
    state = state.copyWith(isPaused: true, clearError: true);
    await stop();
  }

  Future<void> resume() async {
    state = state.copyWith(isPaused: false, clearError: true);
    await start();
  }

  Future<void> _disposeResources() async {
    _wanted = false;
    await _eventSubscription?.cancel();
    if (_nativeReady) {
      try {
        await _methodChannel.invokeMethod<void>('dispose');
      } catch (_) {}
    }
  }

  Future<void> _stopNative() async {
    if (!_nativeReady) return;
    try {
      await _methodChannel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}

/// Formulations reconnues comme un appel au secours.
///
/// Vosk transcrit la parole libre et [matchesSosVoicePhrase] déclenche le SOS
/// si l'une de ces phrases apparaît. La reconnaissance est française
/// uniquement ; une phrase absente d'ici ne déclenchera rien.
const voiceSosPhrases = <String>[
  // Appels directs à l'aide.
  "à l'aide",
  'au secours',
  'secours',
  'aide',
  "aidez-moi",
  "aidez moi",
  "aide-moi",
  "aide moi",
  "venez m'aider",
  'venez vite',
  'venez',
  "à moi",
  "à l'aide vite",
  'au secours vite',
  "s'il vous plaît aidez-moi",
  "quelqu'un peut m'aider",
  "quelqu'un peut m aider",
  // Détresse explicite.
  'je suis en danger',
  'je suis en détresse',
  "j'ai besoin d'aide",
  "j'ai besoin de secours",
  "j'ai besoin d'aide vite",
  'urgence',
  "c'est une urgence",
  'danger',
  'au meurtre',
  // Santé, blessure, malaise.
  'je suis blessé',
  'je suis blessée',
  'je suis tombé',
  'je suis tombée',
  'je saigne',
  'je perds du sang',
  "j'ai mal",
  "j'étouffe",
  'je suffoque',
  'je ne respire plus',
  'je ne peux plus respirer',
  'je ne peux pas respirer',
  'crise cardiaque',
  'je fais une crise',
  'je vais tomber',
  // Immobilité, dépendance.
  'je ne peux pas bouger',
  'je ne peux plus bouger',
  'je suis bloqué',
  'je suis bloquée',
  'je suis coincé',
  'je suis coincée',
  'je suis perdu',
  'je suis perdue',
  // Agression.
  "on m'agresse",
  "on m'attaque",
  'on me suit',
  'je me fais agresser',
  // Incendie.
  'au feu',
  'il y a le feu',
  'ça brûle',
  // Appels à un service d'urgence.
  'appelez la police',
  'appelez les pompiers',
  'appelez les secours',
  'appelez une ambulance',
  'appelez le samu',
  'police',
  'pompiers',
  'ambulance',
  'samu',
  // Accident.
  'accident',
  "il y a eu un accident",
];

String _normalizeVoiceText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ûüù]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp('[^a-z0-9]+'), ' ')
    .trim();

final _voicePhrasePattern = RegExp(
  voiceSosPhrases
      .map((phrase) => RegExp.escape(_normalizeVoiceText(phrase)))
      .join('|'),
);

bool matchesSosVoicePhrase(String words) {
  final normalized = _normalizeVoiceText(words);
  if (normalized.length < 3) return false;
  return _voicePhrasePattern.hasMatch(normalized);
}

Future<void> requestVoiceSosSetup(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(voiceSosProvider.notifier);
  final choice = ref.read(voiceSosProvider).setupChoice;
  if (choice == VoiceSosSetupChoice.accepted) {
    await controller.start();
    return;
  }
  if (choice == VoiceSosSetupChoice.postponed) {
    await controller.acceptVoiceSosSetup();
    return;
  }
  if (choice != VoiceSosSetupChoice.needsPrompt) return;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.mic, color: AppColors.primary),
      title: const Text('Préparer le SOS vocal ?'),
      content: const Text(
        'Un module d’écoute en permanence reste actif durant votre '
        'utilisation de l’application. Il permet aux personnes à mobilité '
        'réduite de déclencher un SOS en cas de danger, simplement en '
        'prononçant une phrase comme « à l’aide » (d’autres formulations '
        'sont également reconnues). La reconnaissance fonctionne localement, '
        'sans connexion Internet : le micro n’est écouté que lorsque '
        'l’application est au premier plan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Oui, le faire maintenant'),
        ),
      ],
    ),
  );
  if (accepted == true) {
    await controller.acceptVoiceSosSetup();
  } else {
    await controller.postponeVoiceSosSetup();
  }
}

class VoiceSosHost extends ConsumerStatefulWidget {
  const VoiceSosHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<VoiceSosHost> createState() => _VoiceSosHostState();
}

class _VoiceSosHostState extends ConsumerState<VoiceSosHost>
    with WidgetsBindingObserver {
  bool _foreground = true;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _scheduleSync();
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      _sync();
    });
  }

  void _sync() {
    if (!mounted) return;
    if (!isVoiceSosSupported) return;
    final authenticated = ref.read(authProvider).user != null;
    if (!authenticated) {
      unawaited(ref.read(voiceSosProvider.notifier).stop());
      return;
    }
    final sos = ref.read(sosControllerProvider);
    final voice = ref.read(voiceSosProvider);
    if (_foreground &&
        authenticated &&
        voice.setupChoice == VoiceSosSetupChoice.accepted &&
        !sos.isRestoring &&
        !sos.hasActiveAlert &&
        sos.status != SosStatus.sending &&
        !voice.isPaused) {
      unawaited(ref.read(voiceSosProvider.notifier).start());
    } else {
      unawaited(ref.read(voiceSosProvider.notifier).stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isVoiceSosSupported) return widget.child;
    ref.listen(authProvider, (_, _) => _scheduleSync());
    final auth = ref.watch(authProvider);
    if (auth.user == null) return widget.child;

    ref.listen(sosControllerProvider, (_, _) => _scheduleSync());
    ref.listen<VoiceSosState>(voiceSosProvider, (previous, next) {
      if (previous?.setupChoice != next.setupChoice) {
        _scheduleSync();
      }
    });
    final sos = ref.watch(sosControllerProvider);
    final voice = ref.watch(voiceSosProvider);
    if (voice.setupChoice != VoiceSosSetupChoice.accepted) {
      return widget.child;
    }
    final alertActive =
        sos.isRestoring ||
        sos.hasActiveAlert ||
        sos.status == SosStatus.sending;

    final label = sos.isRestoring
        ? 'Vérification de votre alerte SOS'
        : sos.status == SosStatus.sending
        ? 'SOS détecté, envoi de l’alerte en cours…'
        : sos.status == SosStatus.loading
        ? 'Annulation du SOS en cours…'
        : sos.hasActiveAlert
        ? 'SOS envoyé. En attente des secours.'
        : sos.status == SosStatus.error
        ? 'Problème SOS : ${sos.errorMessage ?? "ouvrez la page SOS"}'
        : voice.error ??
              (voice.isPaused
                  ? 'Écoute SOS en pause'
                  : voice.isListening
                  ? 'Écoute SOS active'
                  : voice.isLoadingModel
                  ? voice.setupProgress == null
                        ? 'Préparation locale du modèle SOS'
                        : 'Préparation Vosk ${(voice.setupProgress! * 100).round()} %'
                  : 'Initialisation de l’écoute SOS');
    final actionLabel = alertActive
        ? null
        : voice.error != null
        ? 'Réessayer'
        : voice.isPaused
        ? 'Reprendre'
        : 'Pause';

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Material(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    voice.isListening ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (actionLabel != null)
                    TextButton(
                      onPressed: () {
                        final controller = ref.read(voiceSosProvider.notifier);
                        if (voice.error != null || voice.isPaused) {
                          unawaited(controller.resume());
                        } else {
                          unawaited(controller.pause());
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 44),
                      ),
                      child: Text(actionLabel),
                    ),
                ],
              ),
            ),
          ),
          if (voice.isLoadingModel)
            LinearProgressIndicator(
              value: voice.setupProgress,
              minHeight: 3,
              backgroundColor: AppColors.inactive.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(AppColors.secondaryText),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

bool get isVoiceSosSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
