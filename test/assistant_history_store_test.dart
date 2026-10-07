import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/assistant/data/assistant_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists and reloads a conversation per user', () async {
    const store = AssistantHistoryStore();
    await store.save('uid-a', [
      {'text': 'Bonjour', 'user': true},
      {
        'text': 'Restez calme.',
        'reply': {'answer': 'Restez calme.'},
      },
    ]);

    final loaded = await store.load('uid-a');
    expect(loaded, hasLength(2));
    expect(loaded.first['text'], 'Bonjour');
    expect(loaded.first['user'], isTrue);
    expect((loaded.last['reply'] as Map)['answer'], 'Restez calme.');
  });

  test('keeps histories of two users separate', () async {
    const store = AssistantHistoryStore();
    await store.save('uid-a', [
      {'text': 'A', 'user': true},
    ]);
    await store.save('uid-b', [
      {'text': 'B', 'user': true},
    ]);

    expect((await store.load('uid-a')).single['text'], 'A');
    expect((await store.load('uid-b')).single['text'], 'B');
  });

  test('clear removes only the targeted user history', () async {
    const store = AssistantHistoryStore();
    await store.save('uid-a', [
      {'text': 'A', 'user': true},
    ]);
    await store.clear('uid-a');
    expect(await store.load('uid-a'), isEmpty);
  });

  test('caps the stored history to the most recent messages', () async {
    const store = AssistantHistoryStore();
    await store.save('uid-a', [
      for (var i = 0; i < 100; i++) {'text': 'message $i'},
    ]);

    final loaded = await store.load('uid-a');
    expect(loaded.length, lessThanOrEqualTo(60));
    expect(loaded.last['text'], 'message 99');
  });
}
