import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/voice/voice_service.dart';
import 'package:salus/features/assistant/data/assistant_api.dart';
import 'package:salus/features/assistant/data/assistant_history_store.dart';
import 'package:salus/features/assistant/data/terrain_context.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';
import 'package:salus/features/sos/presentation/providers/sos_provider.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_AssistantMessage> _messages = [];
  late final VoiceService _voice;
  bool _sending = false;
  bool _shareLocation = true;
  int? _speakingMessageId;
  int _nextMessageId = 0;

  static const _suggestions = [
    'L’eau monte près de chez moi, que faire ?',
    'Comment me protéger pendant un séisme ?',
    'Où trouver un refuge ?',
  ];

  @override
  void initState() {
    super.initState();
    _voice = ref.read(voiceServiceProvider);
    _voice.isSpeaking.addListener(_onSpeakingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureLocation());
      unawaited(_loadHistory());
    });
  }

  @override
  void dispose() {
    _voice.isSpeaking.removeListener(_onSpeakingChanged);
    unawaited(_voice.stop());
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSpeakingChanged() {
    if (!mounted) return;
    if (!_voice.isSpeaking.value && _speakingMessageId != null) {
      setState(() => _speakingMessageId = null);
    }
  }

  /// Récupère une position si besoin. Le partage est actif par défaut : pas
  /// d'action manuelle, mais un échec GPS ne bloque jamais la conversation.
  Future<bool> _ensureLocation() async {
    if (ref.read(locationProvider).position != null) return true;
    await ref.read(locationProvider.notifier).refresh();
    return ref.read(locationProvider).position != null;
  }

  Future<void> _toggleLocation() async {
    if (_shareLocation) {
      setState(() => _shareLocation = false);
      return;
    }
    await _ensureLocation();
    if (!mounted) return;
    if (ref.read(locationProvider).position == null) {
      final error = ref.read(locationProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Position indisponible. Vous pouvez continuer sans GPS.',
          ),
        ),
      );
      return;
    }
    setState(() => _shareLocation = true);
  }

  String? get _uid => ref.read(authProvider).user?.uid;

  Future<void> _loadHistory() async {
    final uid = _uid;
    if (uid == null) return;
    final stored = await ref.read(assistantHistoryStoreProvider).load(uid);
    if (!mounted || stored.isEmpty) return;
    final restored = <_AssistantMessage>[];
    var id = _nextMessageId;
    for (final item in stored) {
      final message = _AssistantMessage.fromStored(id, item);
      if (message == null) continue;
      restored.add(message);
      id++;
    }
    if (restored.isEmpty) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(restored);
      _nextMessageId = id;
    });
    _scrollToBottom();
  }

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null) return;
    await ref.read(assistantHistoryStoreProvider).save(uid, [
      for (final message in _messages) message.toStored(),
    ]);
  }

  void _appendMessage(_AssistantMessage message) {
    if (!mounted) return;
    setState(() => _messages.add(message));
    unawaited(_persist());
    _scrollToBottom();
  }

  Future<void> _clearHistory() async {
    final uid = _uid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer la conversation ?'),
        content: const Text(
          'Les messages du copilote seront supprimés de cet appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (uid != null) {
      await ref.read(assistantHistoryStoreProvider).clear(uid);
    }
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _nextMessageId = 0;
    });
  }

  /// L'app déclenche le SOS pour l'utilisateur dès que le backend a détecté une
  /// détresse explicite. Le texte du modèle n'est jamais cru sur parole : c'est
  /// une détection serveur déterministe qui décide (`sosRequested`).
  Future<void> _handleSosRequest() async {
    final controller = ref.read(sosControllerProvider.notifier);
    if (ref.read(sosControllerProvider).hasActiveAlert) {
      _appendMessage(
        _AssistantMessage(
          id: _nextMessageId++,
          text: 'Un SOS est déjà en cours. Suivez son état depuis l’écran SOS.',
          sosTriggered: true,
        ),
      );
      return;
    }
    await controller.triggerSos(
      description: 'Déclenché depuis le copilote de crise',
    );
    if (!mounted) return;
    final after = ref.read(sosControllerProvider);
    if (after.hasActiveAlert) {
      _appendMessage(
        _AssistantMessage(
          id: _nextMessageId++,
          text:
              'SOS activé : votre position a été transmise aux personnes proches.',
          sosTriggered: true,
        ),
      );
    } else {
      _appendMessage(
        _AssistantMessage(
          id: _nextMessageId++,
          text:
              after.errorMessage ??
              'Je n’ai pas pu déclencher le SOS. Utilisez le bouton SOS.',
          isError: true,
        ),
      );
    }
  }

  Future<void> _send([String? suggestedMessage]) async {
    final text = (suggestedMessage ?? _inputController.text).trim();
    if (text.isEmpty || _sending) return;
    final history = [
      for (final item in _messages)
        if (!item.isError && !item.sosTriggered)
          AssistantTurn(item.isUser ? 'user' : 'assistant', item.text),
    ];
    final boundedHistory = history.length <= 8
        ? history
        : history.sublist(history.length - 8);
    setState(() => _sending = true);
    _inputController.clear();
    _appendMessage(
      _AssistantMessage(id: _nextMessageId++, text: text, isUser: true),
    );
    try {
      if (_shareLocation && ref.read(locationProvider).position == null) {
        await _ensureLocation();
      }
      final location = _shareLocation
          ? ref.read(locationProvider).position
          : null;
      // Contexte terrain compact (refuges + zones, démo comprise) pour que le
      // copilote cite ce que la carte affiche. Repli : aucune position, aucun
      // contexte.
      final terrain = location == null
          ? null
          : buildTerrainContext(
              originLatitude: location.latitude,
              originLongitude: location.longitude,
              shelters:
                  ref.read(validatedSheltersProvider).value ?? const [],
              zones: <String, Zone>{
                for (final zone
                    in ref.read(activeRiskZonesProvider).value ??
                        const <Zone>[])
                  zone.id: zone,
                for (final zone
                    in ref.read(riskZonesProvider).value ?? const <Zone>[])
                  zone.id: zone,
              }.values.toList(),
            );
      final reply = await ref
          .read(assistantApiProvider)
          .chat(
            message: terrain == null ? text : '$terrain\n$text',
            history: boundedHistory,
            location: location,
          );
      if (!mounted) return;
      _appendMessage(
        _AssistantMessage(
          id: _nextMessageId++,
          text: reply.answer,
          reply: reply,
        ),
      );
      if (reply.sosRequested) {
        await _handleSosRequest();
      }
    } catch (error) {
      if (!mounted) return;
      _appendMessage(
        _AssistantMessage(
          id: _nextMessageId++,
          text: error is AssistantApiException
              ? error.message
              : 'Le copilote est momentanément indisponible. Consultez le guide d’urgence.',
          isError: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleSpeech(_AssistantMessage message) async {
    if (_speakingMessageId == message.id && _voice.isSpeaking.value) {
      await _voice.stop();
      if (mounted) setState(() => _speakingMessageId = null);
      return;
    }
    final available = await _voice.prepare();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La lecture vocale est indisponible sur cet appareil. '
            'La réponse reste affichée à l’écran.',
          ),
        ),
      );
      return;
    }
    setState(() => _speakingMessageId = message.id);
    await _voice.speak(message.text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = ref.watch(authProvider).user != null;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Copilote de crise', style: TextStyle(fontSize: 17)),
            Text(
              'SALUS · assistance IA',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Effacer la conversation',
            onPressed: _messages.isEmpty
                ? null
                : () => unawaited(_clearHistory()),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          IconButton(
            tooltip: 'Guide d’évacuation hors ligne',
            onPressed: () => context.router.push(EvacuationGuideRoute()),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: authenticated
          ? SafeArea(
              top: false,
              child: Column(
                children: [
                  _LocationBar(
                    shared: _shareLocation,
                    onPressed: _toggleLocation,
                  ),
                  Expanded(child: _conversation()),
                  _composer(),
                ],
              ),
            )
          : _loginRequired(),
    );
  }

  Widget _conversation() {
    if (_messages.isEmpty && !_sending) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
        children: [
          const _WelcomeCard(),
          const SizedBox(height: 22),
          const Text(
            'Vous pouvez demander',
            style: TextStyle(
              color: AppColors.inactive,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final suggestion in _suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActionChip(
                avatar: const Icon(Icons.arrow_outward, size: 16),
                label: Text(suggestion),
                onPressed: () => unawaited(_send(suggestion)),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
        ],
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (_sending && index == _messages.length) {
          return const _TypingIndicator();
        }
        final message = _messages[index];
        if (message.sosTriggered) {
          return _SosMessage(
            message: message,
            onOpen: () => context.router.push(const SosRoute()),
          );
        }
        return _MessageBubble(
          message: message,
          speaking: _speakingMessageId == message.id,
          onSpeech: message.isUser || message.isError
              ? null
              : () => unawaited(_toggleSpeech(message)),
          onGuide: message.isError
              ? () => context.router.push(EvacuationGuideRoute())
              : null,
        );
      },
    );
  }

  Widget _composer() => Material(
    color: AppColors.surface,
    elevation: 8,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                enabled: !_sending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => unawaited(_send()),
                decoration: InputDecoration(
                  hintText: 'Décrivez ce qui se passe…',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Envoyer',
              onPressed: _sending ? null : () => unawaited(_send()),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _loginRequired() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 42, color: AppColors.primary),
          const SizedBox(height: 14),
          const Text(
            'Connectez-vous pour utiliser le copilote.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => context.router.push(const LoginRoute()),
            icon: const Icon(Icons.login),
            label: const Text('Se connecter'),
          ),
          TextButton(
            onPressed: () => context.router.push(EvacuationGuideRoute()),
            child: const Text('Ouvrir le guide hors ligne'),
          ),
        ],
      ),
    ),
  );
}

class _AssistantMessage {
  _AssistantMessage({
    required this.id,
    required this.text,
    this.isUser = false,
    this.isError = false,
    this.sosTriggered = false,
    this.reply,
  });

  final int id;
  final String text;
  final bool isUser;
  final bool isError;
  final bool sosTriggered;
  final AssistantReply? reply;

  Map<String, dynamic> toStored() => {
    'text': text,
    if (isUser) 'user': true,
    if (isError) 'error': true,
    if (sosTriggered) 'sos': true,
    if (reply != null) 'reply': reply!.toJson(),
  };

  static _AssistantMessage? fromStored(int id, Map<String, dynamic> json) {
    final text = json['text'];
    if (text is! String || text.isEmpty) return null;
    final replyJson = json['reply'];
    return _AssistantMessage(
      id: id,
      text: text,
      isUser: json['user'] == true,
      isError: json['error'] == true,
      sosTriggered: json['sos'] == true,
      reply: replyJson is Map<String, dynamic>
          ? AssistantReply.fromJson(replyJson)
          : null,
    );
  }
}

class _SosMessage extends StatelessWidget {
  const _SosMessage({required this.message, required this.onOpen});

  final _AssistantMessage message;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 8),
    decoration: BoxDecoration(
      color: AppColors.sos.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.sos.withValues(alpha: 0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sos, color: AppColors.sos, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text,
                style: const TextStyle(
                  color: AppColors.sos,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: const Text('Voir mon SOS'),
            style: TextButton.styleFrom(foregroundColor: AppColors.sos),
          ),
        ),
      ],
    ),
  );
}

class _LocationBar extends StatelessWidget {
  const _LocationBar({required this.shared, required this.onPressed});

  final bool shared;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.primary.withValues(alpha: 0.06),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        Icon(
          shared ? Icons.location_on : Icons.location_searching,
          size: 17,
          color: shared ? AppColors.secondaryText : AppColors.inactive,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            shared
                ? 'Position partagée automatiquement avec SALUS (jamais avec le modèle IA)'
                : 'Sans position, le refuge proche ne sera pas vérifié',
            style: const TextStyle(fontSize: 12, color: AppColors.inactive),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(shared ? 'Retirer' : 'Ajouter'),
        ),
      ],
    ),
  );
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.support_agent, color: AppColors.secondary, size: 30),
        SizedBox(height: 14),
        Text(
          'On va procéder étape par étape.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Décrivez votre situation. Le copilote s’appuie sur les risques et refuges connus de SALUS. En danger immédiat, contactez les secours.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
      ],
    ),
  );
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Le copilote prépare une réponse…',
            style: TextStyle(color: AppColors.inactive),
          ),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.speaking,
    this.onSpeech,
    this.onGuide,
  });

  final _AssistantMessage message;
  final bool speaking;
  final VoidCallback? onSpeech;
  final VoidCallback? onGuide;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    final alignment = user ? Alignment.centerRight : Alignment.centerLeft;
    final color = user ? AppColors.primary : AppColors.surface;
    final foreground = user ? Colors.white : AppColors.primary;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(15, 12, 12, 8),
          decoration: BoxDecoration(
            color: message.isError ? const Color(0xFFFFF1F0) : color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(user ? 18 : 5),
              bottomRight: Radius.circular(user ? 5 : 18),
            ),
            border: user
                ? null
                : Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: message.isError ? AppColors.sos : foreground,
                  height: 1.42,
                ),
              ),
              if (message.reply case final reply?) ...[
                if ((reply.riskSummary ?? '').isNotEmpty ||
                    !reply.riskDataAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      reply.riskSummary ?? 'Données de risque indisponibles.',
                      style: const TextStyle(
                        color: AppColors.inactive,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (reply.shelter case final shelter?)
                  _ShelterRecommendation(shelter: shelter),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: speaking
                        ? 'Arrêter la lecture'
                        : 'Écouter la réponse',
                    onPressed: onSpeech,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      speaking ? Icons.stop_circle : Icons.volume_up_outlined,
                    ),
                  ),
                ),
              ],
              if (onGuide != null)
                TextButton.icon(
                  onPressed: onGuide,
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('Ouvrir le guide d’urgence'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterRecommendation extends StatelessWidget {
  const _ShelterRecommendation({required this.shelter});

  final AssistantShelter shelter;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.home_work_outlined,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shelter.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (shelter.address.isNotEmpty)
                Text(
                  shelter.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inactive,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                '${_statusLabel(shelter.status)} · ${shelter.availablePlaces} places indiquées',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _distanceLabel(shelter.distanceMeters),
                style: const TextStyle(fontSize: 12, color: AppColors.inactive),
              ),
              if (shelter.resources.isNotEmpty)
                Text(
                  shelter.resources.join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inactive,
                  ),
                ),
              if (shelter.latitude != 0 || shelter.longitude != 0)
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.https('www.google.com', '/maps/dir/', {
                      'api': '1',
                      'destination': '${shelter.latitude},${shelter.longitude}',
                    }),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.directions_outlined, size: 17),
                  label: const Text('Ouvrir l’itinéraire'),
                ),
              const Text(
                'Statut susceptible d’avoir changé. Vérifiez avant le départ.',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _distanceLabel(int meters) =>
      meters < 1000 ? '$meters m' : '${(meters / 1000).toStringAsFixed(1)} km';

  String _statusLabel(String status) => switch (status) {
    'almostFull' => 'Presque complet',
    'open' => 'Ouvert',
    _ => 'Statut à vérifier',
  };
}
