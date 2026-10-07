import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/voice/voice_service.dart';

void main() {
  test('keeps short sentences whole so the voice does not stutter', () {
    final chunks = splitForSpeech('Bonjour. Restez calme. Aidez-vous.');
    expect(chunks.length, lessThan(3));
    expect(chunks.join(' '), contains('Bonjour.'));
    expect(chunks.join(' '), contains('Restez calme.'));
  });

  test('absorbs a fragment left alone by punctuation instead of pausing', () {
    final chunks = splitForSpeech('Dr. Rakoto arrive dans deux minutes.');
    expect(chunks, ['Dr. Rakoto arrive dans deux minutes.']);
  });

  test('splits a long run-on into moteur-friendly segments', () {
    final text = List.filled(40, 'mot').join(' ');
    final chunks = splitForSpeech(text, maxLength: 60);
    expect(chunks.length, greaterThan(1));
    for (final chunk in chunks) {
      expect(chunk.length, lessThanOrEqualTo(61));
    }
    expect(chunks.join(' '), text);
  });

  test('ignores blank input', () {
    expect(splitForSpeech('   \n  '), isEmpty);
  });
}
