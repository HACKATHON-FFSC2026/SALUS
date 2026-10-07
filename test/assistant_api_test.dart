import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/assistant/data/assistant_api.dart';

void main() {
  test('decodes a verified shelter card from the assistant response', () {
    final reply = AssistantReply.fromJson({
      'answer': 'Éloignez-vous de la rivière.',
      'riskDataAvailable': true,
      'riskSummary': 'inondation (alerte red)',
      'shelter': {
        'id': 'shelter-1',
        'name': 'Refuge municipal',
        'address': 'Centre-ville',
        'latitude': -18.9,
        'longitude': 47.5,
        'distanceMeters': 850,
        'status': 'open',
        'availablePlaces': 42,
        'resources': ['eau', 'kit médical'],
      },
    });

    expect(reply.answer, 'Éloignez-vous de la rivière.');
    expect(reply.riskDataAvailable, isTrue);
    expect(reply.shelter?.id, 'shelter-1');
    expect(reply.shelter?.latitude, -18.9);
    expect(reply.shelter?.availablePlaces, 42);
    expect(reply.shelter?.resources, ['eau', 'kit médical']);
  });

  test('omits unverified shelter data when the backend provides none', () {
    final reply = AssistantReply.fromJson({
      'answer': 'Je ne peux pas confirmer un refuge proche.',
      'riskDataAvailable': false,
    });

    expect(reply.shelter, isNull);
    expect(reply.riskDataAvailable, isFalse);
  });

  test('serializes only the role and text for bounded chat history', () {
    expect(const AssistantTurn('assistant', 'Restez à distance.').toJson(), {
      'role': 'assistant',
      'content': 'Restez à distance.',
    });
  });

  test('flags an explicit distress message for the app to trigger a SOS', () {
    expect(
      AssistantReply.fromJson({
        'answer': 'Reste où tu es, les secours arrivent.',
        'riskDataAvailable': true,
        'sosRequested': true,
      }).sosRequested,
      isTrue,
    );
    expect(
      AssistantReply.fromJson({
        'answer': 'Boire de l’eau régulièrement.',
        'riskDataAvailable': true,
      }).sosRequested,
      isFalse,
    );
  });

  test('round-trips a reply through json so persisted history keeps it', () {
    final original = AssistantReply.fromJson({
      'answer': 'Éloignez-vous de la rivière.',
      'riskDataAvailable': true,
      'riskSummary': 'inondation',
      'sosRequested': true,
      'shelter': {
        'id': 'shelter-1',
        'name': 'Refuge municipal',
        'address': 'Centre-ville',
        'latitude': -18.9,
        'longitude': 47.5,
        'distanceMeters': 850,
        'status': 'open',
        'availablePlaces': 42,
        'resources': ['eau'],
      },
    });

    final restored = AssistantReply.fromJson(original.toJson());

    expect(restored.answer, original.answer);
    expect(restored.sosRequested, isTrue);
    expect(restored.shelter?.id, 'shelter-1');
    expect(restored.shelter?.resources, ['eau']);
  });
}
