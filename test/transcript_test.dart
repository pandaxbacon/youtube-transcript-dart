import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('Transcript', () {
    test('creates Transcript correctly', () {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: true,
        translationLanguages: [
          TranslationLanguage(languageCode: 'de', languageName: 'German'),
        ],
        transcriptUrl: 'https://example.com/transcript',
      );

      expect(transcript.videoId, equals('test123'));
      expect(transcript.language, equals('English'));
      expect(transcript.languageCode, equals('en'));
      expect(transcript.isGenerated, isFalse);
      expect(transcript.isTranslatable, isTrue);
      expect(transcript.translationLanguages.length, equals(1));
      expect(
        transcript.transcriptUrl,
        equals('https://example.com/transcript'),
      );
    });

    test('creates auto-generated Transcript', () {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English (auto-generated)',
        languageCode: 'en',
        isGenerated: true,
        isTranslatable: false,
        translationLanguages: [],
      );

      expect(transcript.isGenerated, isTrue);
      expect(transcript.isTranslatable, isFalse);
    });

    test('fetch throws when no fetch function provided', () async {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
        transcriptUrl: 'https://example.com/transcript',
      );

      expect(
        () => transcript.fetch(),
        throwsA(isA<TranscriptFetchException>()),
      );
    });

    test('fetch throws when no URL provided', () async {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
      );

      expect(
        () => transcript.fetch(),
        throwsA(isA<TranscriptFetchException>()),
      );
    });

    test('fetch throws PoTokenRequiredException for xpe URLs', () async {
      Future<FetchedTranscript> mockFetch(
        String url,
        bool preserveFormatting,
      ) async {
        return FetchedTranscript(
          videoId: 'test',
          language: 'en',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [],
        );
      }

      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
        transcriptUrl: 'https://example.com/transcript&exp=xpe',
        fetchFunction: mockFetch,
      );

      expect(
        () => transcript.fetch(),
        throwsA(isA<PoTokenRequiredException>()),
      );
    });

    test('fetch succeeds with valid function and URL', () async {
      Future<FetchedTranscript> mockFetch(
        String url,
        bool preserveFormatting,
      ) async {
        return FetchedTranscript(
          videoId: 'test123',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [
            TranscriptSnippet(text: 'Hello', start: 0.0, duration: 1.0),
          ],
        );
      }

      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
        transcriptUrl: 'https://example.com/transcript',
        fetchFunction: mockFetch,
      );

      final fetched = await transcript.fetch();
      expect(fetched.snippets.length, equals(1));
      expect(fetched.snippets.first.text, equals('Hello'));
    });

    test('translate throws when not translatable', () {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
      );

      expect(
        () => transcript.translate('de'),
        throwsA(isA<TranslationNotAvailableException>()),
      );
    });

    test('translate throws for unsupported language', () {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: true,
        translationLanguages: [
          TranslationLanguage(languageCode: 'de', languageName: 'German'),
        ],
      );

      expect(
        () => transcript.translate('fr'),
        throwsA(isA<TranslationNotAvailableException>()),
      );
    });

    test('translate returns new Transcript with translation URL', () {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: true,
        translationLanguages: [
          TranslationLanguage(languageCode: 'de', languageName: 'German'),
        ],
        transcriptUrl: 'https://example.com/transcript?lang=en',
      );

      final translated = transcript.translate('de');
      expect(translated.language, equals('German'));
      expect(translated.languageCode, equals('en')); // Original language code
      expect(translated.translationLanguageCode, equals('de'));
      expect(translated.transcriptUrl, contains('tlang=de'));
      expect(translated.isTranslatable, isFalse);
    });

    test('translate replaces existing tlang parameter', () {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: true,
        translationLanguages: [
          TranslationLanguage(languageCode: 'de', languageName: 'German'),
        ],
        transcriptUrl: 'https://example.com/transcript?lang=en&tlang=fr',
      );

      final translated = transcript.translate('de');
      expect(translated.transcriptUrl, contains('tlang=de'));
      expect(translated.transcriptUrl!.indexOf('tlang=fr'), equals(-1));
    });

    test('toString returns expected format', () {
      final transcript = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: true,
        translationLanguages: [],
      );

      final str = transcript.toString();
      expect(str, contains('Transcript'));
      expect(str, contains('test123'));
      expect(str, contains('English'));
      expect(str, contains('en'));
    });

    test('equality works correctly', () {
      final transcript1 = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
      );

      final transcript2 = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
      );

      final transcript3 = Transcript(
        videoId: 'test123',
        language: 'German',
        languageCode: 'de',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
      );

      expect(transcript1, equals(transcript2));
      expect(transcript1, isNot(equals(transcript3)));
    });

    test('hashCode is consistent with equality', () {
      final transcript1 = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
      );

      final transcript2 = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: false,
        translationLanguages: [],
      );

      expect(transcript1.hashCode, equals(transcript2.hashCode));
    });
  });
}
