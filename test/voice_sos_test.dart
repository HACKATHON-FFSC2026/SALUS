import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/sos/presentation/voice_sos.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('recognizes French SOS phrases despite accents and punctuation', () {
    expect(matchesSosVoicePhrase('À l’aide !'), isTrue);
    expect(matchesSosVoicePhrase('Je crie au secours maintenant'), isTrue);
    expect(matchesSosVoicePhrase('j’appelle les secours'), isTrue);
    expect(matchesSosVoicePhrase('aidez-moi'), isTrue);
    expect(matchesSosVoicePhrase('je suis en détresse'), isTrue);
    expect(matchesSosVoicePhrase('je ne peux plus respirer'), isTrue);
    expect(matchesSosVoicePhrase('il y a le feu'), isTrue);
    expect(matchesSosVoicePhrase('appelez une ambulance'), isTrue);
  });

  test('ignores ordinary speech and Vosk unknown output', () {
    expect(matchesSosVoicePhrase('bonjour comment ça va'), isFalse);
    expect(matchesSosVoicePhrase('unk'), isFalse);
    expect(matchesSosVoicePhrase(''), isFalse);
    expect(matchesSosVoicePhrase('au'), isFalse);
  });

  testWidgets('explains local model preparation and remembers postponement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final consent = ref.watch(voiceSosProvider).setupChoice;
                return Column(
                  children: [
                    Text(consent.name),
                    TextButton(
                      onPressed: () => requestVoiceSosSetup(context, ref),
                      child: const Text('Configurer'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('needsPrompt'), findsOneWidget);
    await tester.tap(find.text('Configurer'));
    await tester.pumpAndSettle();
    expect(find.text('Préparer le SOS vocal ?'), findsOneWidget);
    expect(find.textContaining('mobilité réduite'), findsOneWidget);
    expect(find.text('Oui, le faire maintenant'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    expect(find.text('postponed'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getInt('voice_sos_setup_choice'),
      1,
    );
  });
}
