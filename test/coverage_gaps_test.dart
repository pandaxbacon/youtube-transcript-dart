import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('Coverage gap fillers', () {
    test('TextFormatter fileExtension is txt', () {
      expect(TextFormatter().fileExtension, equals('txt'));
    });

    test('TextFormatter mimeType is text/plain', () {
      expect(TextFormatter().mimeType, equals('text/plain'));
    });

    test('TranslationLanguage toString contains code and name', () {
      final tl =
          TranslationLanguage(languageCode: 'fr', languageName: 'French');
      expect(tl.toString(), contains('fr'));
      expect(tl.toString(), contains('French'));
    });

    test('JsonFormatter fileExtension is json', () {
      expect(JsonFormatter().fileExtension, equals('json'));
    });

    test('JsonFormatter mimeType is application/json', () {
      expect(JsonFormatter().mimeType, equals('application/json'));
    });

    test('JsonFormatterWithMetadata fileExtension is json', () {
      expect(JsonFormatterWithMetadata().fileExtension, equals('json'));
    });

    test('TextFormatterWithTimestamps fileExtension is txt', () {
      expect(TextFormatterWithTimestamps().fileExtension, equals('txt'));
    });

    test('TranscriptList returns length', () {
      final tl = TranscriptList(videoId: 'test', transcripts: []);
      expect(tl.length, equals(0));
    });
  });
}
