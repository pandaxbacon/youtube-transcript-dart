import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('TranscriptList', () {
    late TranscriptList transcriptList;
    late Transcript manualEnglish;
    late Transcript generatedEnglish;
    late Transcript manualGerman;

    setUp(() {
      manualEnglish = Transcript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslatable: true,
        translationLanguages: [
          TranslationLanguage(languageCode: 'de', languageName: 'German'),
        ],
      );

      generatedEnglish = Transcript(
        videoId: 'test123',
        language: 'English (auto-generated)',
        languageCode: 'en',
        isGenerated: true,
        isTranslatable: false,
        translationLanguages: [],
      );

      manualGerman = Transcript(
        videoId: 'test123',
        language: 'German',
        languageCode: 'de',
        isGenerated: false,
        isTranslatable: true,
        translationLanguages: [
          TranslationLanguage(languageCode: 'en', languageName: 'English'),
        ],
      );

      transcriptList = TranscriptList(
        videoId: 'test123',
        transcripts: [manualEnglish, generatedEnglish, manualGerman],
      );
    });

    test('creates TranscriptList correctly', () {
      expect(transcriptList.videoId, equals('test123'));
      expect(transcriptList.transcripts.length, equals(3));
    });

    test('is iterable', () {
      final languages = <String>[];
      for (final transcript in transcriptList) {
        languages.add(transcript.languageCode);
      }
      expect(languages, equals(['en', 'en', 'de']));
    });

    test('findTranscript prefers manual over generated', () {
      final found = transcriptList.findTranscript(['en']);
      expect(found.isGenerated, isFalse);
      expect(found.languageCode, equals('en'));
    });

    test('findTranscript falls back to generated if no manual', () {
      // Create list with only generated transcript
      final onlyGenerated = TranscriptList(
        videoId: 'test123',
        transcripts: [generatedEnglish],
      );

      final found = onlyGenerated.findTranscript(['en']);
      expect(found.isGenerated, isTrue);
    });

    test('findTranscript respects language priority', () {
      final found = transcriptList.findTranscript(['de', 'en']);
      expect(found.languageCode, equals('de'));
    });

    test(
      'findTranscript throws NoTranscriptFoundException for missing language',
      () {
        expect(
          () => transcriptList.findTranscript(['fr']),
          throwsA(isA<NoTranscriptFoundException>()),
        );
      },
    );

    test('findTranscript exception includes available languages', () {
      try {
        transcriptList.findTranscript(['fr', 'es']);
        fail('Expected exception');
      } catch (e) {
        expect(e, isA<NoTranscriptFoundException>());
        final exception = e as NoTranscriptFoundException;
        expect(exception.requestedLanguages, equals(['fr', 'es']));
        expect(exception.availableLanguages, contains('en'));
        expect(exception.availableLanguages, contains('de'));
      }
    });

    test('findManuallyCreatedTranscript finds manual transcript', () {
      final found = transcriptList.findManuallyCreatedTranscript(['en']);
      expect(found.isGenerated, isFalse);
      expect(found.languageCode, equals('en'));
    });

    test('findManuallyCreatedTranscript throws for missing manual', () {
      // Create list with only generated
      final onlyGenerated = TranscriptList(
        videoId: 'test123',
        transcripts: [generatedEnglish],
      );

      expect(
        () => onlyGenerated.findManuallyCreatedTranscript(['en']),
        throwsA(isA<NoTranscriptManuallyCreatedException>()),
      );
    });

    test('findGeneratedTranscript finds generated transcript', () {
      final found = transcriptList.findGeneratedTranscript(['en']);
      expect(found.isGenerated, isTrue);
    });

    test('findGeneratedTranscript throws for missing generated', () {
      // Create list with only manual
      final onlyManual = TranscriptList(
        videoId: 'test123',
        transcripts: [manualEnglish],
      );

      expect(
        () => onlyManual.findGeneratedTranscript(['en']),
        throwsA(isA<NoTranscriptGeneratedException>()),
      );
    });

    test('toString returns expected format', () {
      final str = transcriptList.toString();
      expect(str, contains('TranscriptList'));
      expect(str, contains('test123'));
      expect(str, contains('3'));
    });

    test('handles empty transcript list', () {
      final emptyList = TranscriptList(videoId: 'test123', transcripts: []);

      expect(
        () => emptyList.findTranscript(['en']),
        throwsA(isA<NoTranscriptFoundException>()),
      );
    });
  });
}
