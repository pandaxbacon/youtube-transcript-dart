import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('FetchedTranscript Extended', () {
    test('creates FetchedTranscript with all properties', () {
      final transcript = FetchedTranscript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: true,
        isTranslated: false,
        snippets: [TranscriptSnippet(text: 'Hello', start: 0.0, duration: 1.0)],
      );

      expect(transcript.videoId, equals('test123'));
      expect(transcript.language, equals('English'));
      expect(transcript.languageCode, equals('en'));
      expect(transcript.isGenerated, isTrue);
      expect(transcript.isTranslated, isFalse);
    });

    test('iterator works correctly', () {
      final transcript = FetchedTranscript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslated: false,
        snippets: [
          TranscriptSnippet(text: 'First', start: 0.0, duration: 1.0),
          TranscriptSnippet(text: 'Second', start: 1.0, duration: 1.0),
          TranscriptSnippet(text: 'Third', start: 2.0, duration: 1.0),
        ],
      );

      final texts = <String>[];
      for (final snippet in transcript) {
        texts.add(snippet.text);
      }

      expect(texts, equals(['First', 'Second', 'Third']));
    });

    test('toRawData returns list of maps', () {
      final transcript = FetchedTranscript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslated: false,
        snippets: [
          TranscriptSnippet(text: 'Hello', start: 0.0, duration: 1.5),
          TranscriptSnippet(text: 'World', start: 1.5, duration: 2.0),
        ],
      );

      final rawData = transcript.toRawData();
      expect(rawData.length, equals(2));

      expect(rawData[0]['text'], equals('Hello'));
      expect(rawData[0]['start'], equals(0.0));
      expect(rawData[0]['duration'], equals(1.5));

      expect(rawData[1]['text'], equals('World'));
      expect(rawData[1]['start'], equals(1.5));
      expect(rawData[1]['duration'], equals(2.0));
    });

    test('toString returns expected format', () {
      final transcript = FetchedTranscript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: true,
        isTranslated: false,
        snippets: [TranscriptSnippet(text: 'Hello', start: 0.0, duration: 1.0)],
      );

      final str = transcript.toString();
      expect(str, contains('FetchedTranscript'));
      expect(str, contains('test123'));
      expect(str, contains('English'));
      expect(str, contains('en'));
      expect(str, contains('isGenerated: true'));
      expect(str, contains('snippets: 1'));
    });

    test('handles empty snippets', () {
      final transcript = FetchedTranscript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslated: false,
        snippets: [],
      );

      expect(transcript.snippets, isEmpty);
      expect(transcript.toRawData(), isEmpty);

      var count = 0;
      for (final _ in transcript) {
        count++;
      }
      expect(count, equals(0));
    });

    test('supports Iterable methods', () {
      final transcript = FetchedTranscript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslated: false,
        snippets: [
          TranscriptSnippet(text: 'First', start: 0.0, duration: 1.0),
          TranscriptSnippet(text: 'Second', start: 1.0, duration: 1.0),
        ],
      );

      expect(transcript.length, equals(2));
      expect(transcript.first.text, equals('First'));
      expect(transcript.last.text, equals('Second'));
      expect(transcript.isEmpty, isFalse);
      expect(transcript.isNotEmpty, isTrue);
    });
  });

  group('TranscriptSnippet Extended', () {
    test('fromJson handles integer values', () {
      final json = {
        'text': 'Hello',
        'start': 5, // integer
        'duration': 3, // integer
      };

      final snippet = TranscriptSnippet.fromJson(json);
      expect(snippet.text, equals('Hello'));
      expect(snippet.start, equals(5.0));
      expect(snippet.duration, equals(3.0));
    });

    test('fromJson handles double values', () {
      final json = {'text': 'Hello', 'start': 5.5, 'duration': 3.25};

      final snippet = TranscriptSnippet.fromJson(json);
      expect(snippet.start, equals(5.5));
      expect(snippet.duration, equals(3.25));
    });

    test('toJson produces valid JSON', () {
      final snippet = TranscriptSnippet(
        text: 'Hello, World!',
        start: 10.5,
        duration: 2.75,
      );

      final json = snippet.toJson();
      expect(json['text'], equals('Hello, World!'));
      expect(json['start'], equals(10.5));
      expect(json['duration'], equals(2.75));
    });

    test('toString returns expected format', () {
      final snippet = TranscriptSnippet(
        text: 'Hello',
        start: 0.0,
        duration: 1.5,
      );

      final str = snippet.toString();
      expect(str, contains('TranscriptSnippet'));
      expect(str, contains('Hello'));
      expect(str, contains('0.0'));
      expect(str, contains('1.5'));
    });

    test('equality is based on all fields', () {
      final s1 = TranscriptSnippet(text: 'A', start: 1.0, duration: 2.0);
      final s2 = TranscriptSnippet(text: 'A', start: 1.0, duration: 2.0);
      final s3 = TranscriptSnippet(text: 'B', start: 1.0, duration: 2.0);
      final s4 = TranscriptSnippet(text: 'A', start: 2.0, duration: 2.0);
      final s5 = TranscriptSnippet(text: 'A', start: 1.0, duration: 3.0);

      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
      expect(s1, isNot(equals(s4)));
      expect(s1, isNot(equals(s5)));
    });

    test('hashCode is consistent with equality', () {
      final s1 = TranscriptSnippet(text: 'A', start: 1.0, duration: 2.0);
      final s2 = TranscriptSnippet(text: 'A', start: 1.0, duration: 2.0);

      expect(s1.hashCode, equals(s2.hashCode));
    });
  });

  group('TranslationLanguage Extended', () {
    test('toString returns expected format', () {
      final lang = TranslationLanguage(
        languageCode: 'de',
        languageName: 'German',
      );

      final str = lang.toString();
      expect(str, contains('TranslationLanguage'));
      expect(str, contains('de'));
      expect(str, contains('German'));
    });

    test('equality is based on both fields', () {
      final l1 = TranslationLanguage(
        languageCode: 'en',
        languageName: 'English',
      );
      final l2 = TranslationLanguage(
        languageCode: 'en',
        languageName: 'English',
      );
      final l3 = TranslationLanguage(
        languageCode: 'en',
        languageName: 'Anglais',
      );
      final l4 = TranslationLanguage(
        languageCode: 'de',
        languageName: 'English',
      );

      expect(l1, equals(l2));
      expect(l1, isNot(equals(l3)));
      expect(l1, isNot(equals(l4)));
    });
  });
}
