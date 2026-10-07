import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/utils/log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale de la conversation du copilote, par utilisateur.
///
/// ponytail: stockage local (`shared_preferences`) volontaire — une discussion
/// de détresse est sensible et n'a pas besoin de quitter l'appareil. Passer à
/// Firestore le jour où la reprise multi-appareils devient nécessaire.
class AssistantHistoryStore {
  const AssistantHistoryStore();

  static const _maxMessages = 60;

  static String _key(String uid) => 'assistant_history_$uid';

  Future<List<Map<String, dynamic>>> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (error) {
      Log.warning('Historique copilote illisible: $error');
      return const [];
    }
  }

  Future<void> save(String uid, List<Map<String, dynamic>> messages) async {
    final bounded = messages.length <= _maxMessages
        ? messages
        : messages.sublist(messages.length - _maxMessages);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(uid), jsonEncode(bounded));
    } catch (error) {
      Log.warning('Historique copilote non enregistré: $error');
    }
  }

  Future<void> clear(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (error) {
      Log.warning('Historique copilote non effacé: $error');
    }
  }
}

final assistantHistoryStoreProvider = Provider<AssistantHistoryStore>(
  (ref) => const AssistantHistoryStore(),
);
