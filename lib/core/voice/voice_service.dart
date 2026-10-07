import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:salus/core/utils/log.dart';

/// Lit du texte à voix haute via le moteur natif Android (TextToSpeech).
/// iOS n'est pas ciblé pour l'instant.
///
/// Stratégie de fluidité et de naturel :
/// - **Phrase par phrase.** Le texte est découpé en phrases puis mis en file :
///   la première démarre tout de suite (latence faible) pendant que les
///   suivantes s'enchaînent sans blanc, et la prosodie reste naturelle.
/// - **File d'attente native.** `awaitSpeakCompletion(false)` + `QUEUE_ADD`
///   laissent le moteur enchaîner les segments au lieu de redémarrer à chaque
///   appel, ce qui produirait des coupures.
/// - **Voix française choisie, pas subie.** On sélectionne explicitement une
///   voix `fr`; par défaut une voix réseau, plus naturelle. Un repli local
///   automatique évite le silence si la voix réseau échoue.
/// - **Débit lisible.** Un débit légèrement inférieur au défaut garde
///   l'intelligibilité, qui prime sur la vitesse pour des consignes de secours.
/// - **Focus audio.** Les consignes prennent le focus pour ne pas se mélanger
///   à une autre lecture.
class VoiceService {
  VoiceService({FlutterTts? tts, this.language = 'fr-FR'})
    : _tts = tts ?? FlutterTts();

  /// Locale de lecture forcée. Les phrases reconnues et les consignes sont
  /// françaises.
  final String language;

  final FlutterTts _tts;
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  Future<void>? _initFuture;
  bool _available = false;
  Timer? _silenceTimer;
  bool _disposed = false;

  /// Vrai quand la voix sélectionnée exige le réseau (Android). Sert à savoir
  /// s'il faut se replier sur la voix locale en cas d'échec.
  bool _networkVoiceActive = false;

  /// Dernier texte demandé, rejoué tel quel si la voix réseau échoue.
  String? _lastText;

  /// Évite que plusieurs erreurs du même segment ne déclenchent plusieurs replis.
  bool _recovering = false;

  /// Vrai après une initialisation réussie avec au moins une voix française.
  bool get isAvailable => _available;

  /// Prépare le moteur une seule fois. Renvoie `true` si la lecture est
  /// possible. Ne lève jamais : l'absence de moteur TTS ne doit pas casser
  /// l'application.
  Future<bool> prepare() async {
    await (_initFuture ??= _initialize());
    return _available;
  }

  Future<void> _initialize() async {
    try {
      // Rendre la main immédiatement et laisser le moteur enfiler les
      // segments: indispensable pour un enchaînement sans blanc.
      await _tts.awaitSpeakCompletion(false);

      final supported = await _tts.isLanguageAvailable(language);
      if (supported != true) {
        Log.warning('Aucune voix TTS pour $language');
        _available = false;
        return;
      }

      await _tts.setLanguage(language);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      // Réglages propres à Android. iOS n'est pas ciblé pour l'instant.
      if (!kIsWeb && Platform.isAndroid) {
        await _tts.setQueueMode(_queueAdd);
        await _selectFrenchVoice();
      }

      _tts.setStartHandler(_onStart);
      _tts.setCompletionHandler(_onDone);
      _tts.setCancelHandler(_onDone);
      _tts.setErrorHandler((message) {
        Log.warning('Erreur TTS: $message');
        unawaited(_recoverFromSpeechError());
      });

      _available = true;
    } catch (error, stack) {
      Log.error('Initialisation TTS impossible', error, stack);
      _available = false;
    }
  }

  /// Lit [text]. Avec [interrupt], coupe la lecture en cours pour repartir du
  /// nouveau texte ; sinon, l'ajoute à la file (utile pour du streaming).
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (_disposed) return;
    if (!await prepare()) return;

    final chunks = splitForSpeech(text);
    if (chunks.isEmpty) return;

    if (interrupt) await stop();
    _lastText = text;
    _setSpeaking(true);
    for (final chunk in chunks) {
      // `focus: true` (Android) demande le focus audio pour ne pas se mélanger
      // à une autre lecture.
      await _tts.speak(chunk, focus: true);
    }
  }

  /// Coupe la lecture et remet l'état à l'arrêt.
  Future<void> stop() async {
    _silenceTimer?.cancel();
    if (_available) {
      try {
        await _tts.stop();
      } catch (error) {
        Log.warning('Arrêt TTS impossible: $error');
      }
    }
    _setSpeaking(false);
  }

  /// Met en pause quand le moteur le supporte (Android).
  Future<void> pause() async {
    if (!_available) return;
    try {
      await _tts.pause();
    } catch (_) {
      // iOS ne met pas en pause; on coupe, l'appelant peut relancer.
      await stop();
    }
  }

  void _onStart() {
    _silenceTimer?.cancel();
    _setSpeaking(true);
  }

  // Le moteur signale la fin de *chaque* segment. Un court délai après le
  // dernier évite que l'état clignote entre deux phrases.
  void _onDone() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(milliseconds: 400), () {
      _setSpeaking(false);
    });
  }

  void _setSpeaking(bool value) {
    if (_disposed || isSpeaking.value == value) return;
    isSpeaking.value = value;
  }

  Future<void> _selectFrenchVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;

    final french = <Map<dynamic, dynamic>>[
      for (final voice in voices)
        if (voice is Map &&
            voice['locale'].toString().toLowerCase().startsWith('fr'))
          voice,
    ];
    if (french.isEmpty) return;

    // Le français de France d'abord : une voix fr-CA est perçue comme
    // « canadienne », pas comme un français neutre. On ne retombe sur les
    // autres locales francophones que s'il n'existe aucune voix fr-FR.
    final france = <Map<dynamic, dynamic>>[
      for (final voice in french)
        if (voice['locale'].toString().toLowerCase().startsWith('fr-fr'))
          voice,
    ];
    final base = france.isNotEmpty ? france : french;

    final pool = _preferOfflineVoices
        ? base.where(_isLocalVoice).toList()
        : base.where(_isNetworkVoice).toList();
    final candidates = pool.isEmpty ? base : pool;
    candidates.sort(
      (a, b) => _voiceQualityRank(b).compareTo(_voiceQualityRank(a)),
    );

    final selected = candidates.first;
    final name = selected['name']?.toString();
    final locale = selected['locale']?.toString();
    if (name == null || locale == null) return;
    try {
      await _tts.setVoice({'name': name, 'locale': locale});
      // Sur Android, une voix « network » peut rester muette sans réseau. On
      // retient qu'on en utilise une pour pouvoir se replier à l'erreur.
      _networkVoiceActive =
          !kIsWeb && Platform.isAndroid && _isNetworkVoice(selected);
    } catch (error) {
      Log.warning('Sélection de voix TTS impossible: $error');
    }
  }

  /// Une erreur du moteur survient d'abord avec la voix réseau
  /// (`ERROR_NETWORK_TIMEOUT`, `-7`) quand la connexion manque. On ne se
  /// contente pas d'ignorer la voix réseau : on la garde par défaut et, en cas
  /// d'échec, on bascule sur la voix locale en rejouant le texte en entier,
  /// sinon la lecture s'arrête au milieu d'une phrase.
  Future<void> _recoverFromSpeechError() async {
    if (_recovering) return;
    if (!_networkVoiceActive) {
      _onDone();
      return;
    }
    _recovering = true;
    _networkVoiceActive = false;
    try {
      await _tts.stop();
      await _tts.clearVoice();
    } catch (_) {}
    Log.warning('Voix TTS réseau indisponible, repli sur la voix locale.');
    final text = _lastText;
    _recovering = false;
    if (_disposed || text == null) {
      _onDone();
      return;
    }
    unawaited(speak(text));
  }

  Future<void> dispose() async {
    _disposed = true;
    _silenceTimer?.cancel();
    try {
      await _tts.stop();
    } catch (_) {}
    isSpeaking.dispose();
  }
}

/// Un seul instantané de lecture partagé par toute l'application.
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(service.dispose);
  return service;
});

/// Débit de lecture. `1.0` allait trop vite ; on ralentit à `0.5` pour rester
/// clair et posé sur des consignes d'urgence.
const _speechRate = 0.5;

/// `QUEUE_ADD` (Android) : ajoute à la file au lieu de remplacer, pour un
/// enchaînement fluide des phrases.
const _queueAdd = 1;

/// `false` = privilégier les voix réseau (plus naturelles). En cas d'échec
/// réseau, [VoiceService._recoverFromSpeechError] bascule sur la voix locale et
/// rejoue le texte, donc on ne sacrifie pas la qualité par défaut.
/// `true` = privilégier directement les voix installées (hors connexion).
const _preferOfflineVoices = false;

bool _isLocalVoice(Map<dynamic, dynamic> voice) {
  final name = voice['name'].toString().toLowerCase();
  return name.contains('local') ||
      name.contains('offline') ||
      voice['networkRequired'] == false;
}

bool _isNetworkVoice(Map<dynamic, dynamic> voice) =>
    voice['name'].toString().toLowerCase().contains('network');

int _voiceQualityRank(Map<dynamic, dynamic> voice) {
  final name = voice['name'].toString().toLowerCase();
  final quality = voice['quality']?.toString().toLowerCase() ?? '';
  if (name.contains('siri')) return 5;
  if (quality == 'premium' || name.contains('premium')) return 4;
  if (quality == 'enhanced' || name.contains('enhanced')) return 3;
  return 1;
}

/// Découpe [text] en segments prononçables.
///
/// Les segments courts (moins de [_minChunkLength]) sont absorbés par le
/// suivant : une phrase comme « Dr. » isolée par la ponctuation ne produit pas
/// de pause artificielle. Les segments trop longs sont recoupés sur une
/// virgule ou un espace pour rester dans une longueur que le moteur gère bien.
@visibleForTesting
List<String> splitForSpeech(
  String text, {
  int maxLength = 240,
  int minLength = 12,
}) {
  final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.isEmpty) return const [];

  final pieces = <String>[];
  for (final sentence in cleaned.split(RegExp(r'(?<=[.!?…])\s'))) {
    pieces.addAll(_splitLongSegment(sentence, maxLength));
  }

  final chunks = <String>[];
  var buffer = '';
  for (final piece in pieces) {
    final trimmed = piece.trim();
    if (trimmed.isEmpty) continue;
    buffer = buffer.isEmpty ? trimmed : '$buffer $trimmed';
    if (buffer.length >= minLength) {
      chunks.add(buffer);
      buffer = '';
    }
  }
  if (buffer.isNotEmpty) {
    if (chunks.isEmpty) {
      chunks.add(buffer);
    } else {
      chunks[chunks.length - 1] = '${chunks.last} $buffer';
    }
  }
  return chunks;
}

Iterable<String> _splitLongSegment(String segment, int maxLength) sync* {
  var remaining = segment.trim();
  while (remaining.length > maxLength) {
    final window = remaining.substring(0, maxLength);
    var cut = window.lastIndexOf(RegExp(r'[,;:] '));
    if (cut < maxLength ~/ 2) cut = window.lastIndexOf(' ');
    if (cut <= 0) cut = maxLength;
    yield remaining.substring(0, cut + 1).trim();
    remaining = remaining.substring(cut + 1).trim();
  }
  if (remaining.isNotEmpty) yield remaining;
}
