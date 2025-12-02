import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('Formatters Extended', () {
    late FetchedTranscript sampleTranscript;
    late FetchedTranscript longTranscript;

    setUp(() {
      sampleTranscript = FetchedTranscript(
        videoId: 'test123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslated: false,
        snippets: [
          TranscriptSnippet(text: 'Hello, world!', start: 0.0, duration: 2.5),
          TranscriptSnippet(text: 'This is a test.', start: 2.5, duration: 3.0),
        ],
      );

      // Transcript that spans more than an hour
      longTranscript = FetchedTranscript(
        videoId: 'long123',
        language: 'English',
        languageCode: 'en',
        isGenerated: false,
        isTranslated: false,
        snippets: [
          TranscriptSnippet(text: 'Start', start: 0.0, duration: 2.0),
          TranscriptSnippet(text: 'One hour', start: 3600.0, duration: 2.0),
          TranscriptSnippet(text: 'Two hours', start: 7200.5, duration: 3.5),
        ],
      );
    });

    group('TextFormatter', () {
      test('empty transcript returns empty string', () {
        final empty = FetchedTranscript(
          videoId: 'test',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [],
        );

        final formatter = TextFormatter();
        expect(formatter.format(empty), isEmpty);
      });

      test('single snippet has no newline', () {
        final single = FetchedTranscript(
          videoId: 'test',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [
            TranscriptSnippet(text: 'Only one', start: 0.0, duration: 1.0),
          ],
        );

        final formatter = TextFormatter();
        final result = formatter.format(single);
        expect(result, equals('Only one'));
        expect(result.contains('\n'), isFalse);
      });
    });

    group('TextFormatterWithTimestamps', () {
      test('formats with decimal timestamps', () {
        final transcript = FetchedTranscript(
          videoId: 'test',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [
            TranscriptSnippet(text: 'Precise', start: 1.234, duration: 1.0),
          ],
        );

        final formatter = TextFormatterWithTimestamps();
        final result = formatter.format(transcript);
        expect(result, contains('[1.234]'));
      });
    });

    group('JsonFormatter', () {
      test('non-pretty JSON is compact', () {
        final formatter = JsonFormatter(pretty: false);
        final result = formatter.format(sampleTranscript);
        expect(result.contains('\n'), isFalse);
        expect(result.contains('  '), isFalse);
      });

      test('pretty JSON has indentation', () {
        final formatter = JsonFormatter(pretty: true);
        final result = formatter.format(sampleTranscript);
        expect(result.contains('\n'), isTrue);
        expect(result.contains('  '), isTrue);
      });

      test('handles special characters in text', () {
        final transcript = FetchedTranscript(
          videoId: 'test',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [
            TranscriptSnippet(
              text: 'Quote "test" here',
              start: 0.0,
              duration: 1.0,
            ),
            TranscriptSnippet(
              text: 'Backslash \\ here',
              start: 1.0,
              duration: 1.0,
            ),
          ],
        );

        final formatter = JsonFormatter();
        final result = formatter.format(transcript);
        // JSON should properly escape quotes and backslashes
        expect(result, contains('\\"'));
        expect(result, contains('\\\\'));
      });
    });

    group('JsonFormatterWithMetadata', () {
      test('includes all metadata fields', () {
        final formatter = JsonFormatterWithMetadata(pretty: true);
        final result = formatter.format(sampleTranscript);

        expect(result, contains('"videoId"'));
        expect(result, contains('"language"'));
        expect(result, contains('"languageCode"'));
        expect(result, contains('"isGenerated"'));
        expect(result, contains('"isTranslated"'));
        expect(result, contains('"transcripts"'));
      });

      test('non-pretty JSON is compact', () {
        final formatter = JsonFormatterWithMetadata(pretty: false);
        final result = formatter.format(sampleTranscript);
        expect(result.contains('\n'), isFalse);
      });
    });

    group('VttFormatter', () {
      test('starts with WEBVTT header', () {
        final formatter = VttFormatter();
        final result = formatter.format(sampleTranscript);
        expect(result.startsWith('WEBVTT'), isTrue);
      });

      test('formats hours correctly', () {
        final formatter = VttFormatter();
        final result = formatter.format(longTranscript);

        expect(result, contains('00:00:00.000'));
        expect(result, contains('01:00:00.000'));
        expect(result, contains('02:00:00.500'));
      });

      test('formats milliseconds correctly', () {
        final transcript = FetchedTranscript(
          videoId: 'test',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [
            TranscriptSnippet(text: 'Test', start: 1.456, duration: 2.789),
          ],
        );

        final formatter = VttFormatter();
        final result = formatter.format(transcript);
        // Check format is roughly correct (allowing for floating point)
        expect(result, contains('00:00:01.'));
        expect(result, contains('00:00:04.'));
      });

      test('has correct file extension', () {
        final formatter = VttFormatter();
        expect(formatter.fileExtension, equals('vtt'));
      });

      test('has correct mime type', () {
        final formatter = VttFormatter();
        expect(formatter.mimeType, equals('text/vtt'));
      });
    });

    group('SrtFormatter', () {
      test('has sequential indices', () {
        final formatter = SrtFormatter();
        final result = formatter.format(sampleTranscript);

        expect(result, contains('1\n'));
        expect(result, contains('2\n'));
      });

      test('uses comma for milliseconds', () {
        final formatter = SrtFormatter();
        final result = formatter.format(sampleTranscript);

        // SRT uses comma, not period
        expect(result, contains(',000'));
        expect(result, contains(',500'));
      });

      test('formats long videos correctly', () {
        final formatter = SrtFormatter();
        final result = formatter.format(longTranscript);

        expect(result, contains('01:00:00,000'));
        expect(result, contains('02:00:00,500'));
      });

      test('has correct file extension', () {
        final formatter = SrtFormatter();
        expect(formatter.fileExtension, equals('srt'));
      });

      test('has correct mime type', () {
        final formatter = SrtFormatter();
        expect(formatter.mimeType, equals('application/x-subrip'));
      });
    });

    group('CsvFormatter', () {
      test('escapes text with newlines', () {
        final transcript = FetchedTranscript(
          videoId: 'test',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [
            TranscriptSnippet(text: 'Line1\nLine2', start: 0.0, duration: 1.0),
          ],
        );

        final formatter = CsvFormatter(includeHeader: false);
        final result = formatter.format(transcript);
        expect(result, contains('"Line1\nLine2"'));
      });

      test('escapes text with carriage return', () {
        final transcript = FetchedTranscript(
          videoId: 'test',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [
            TranscriptSnippet(text: 'Line1\rLine2', start: 0.0, duration: 1.0),
          ],
        );

        final formatter = CsvFormatter(includeHeader: false);
        final result = formatter.format(transcript);
        expect(result, contains('"Line1\rLine2"'));
      });

      test('does not escape simple text', () {
        final transcript = FetchedTranscript(
          videoId: 'test',
          language: 'English',
          languageCode: 'en',
          isGenerated: false,
          isTranslated: false,
          snippets: [
            TranscriptSnippet(text: 'Simple text', start: 0.0, duration: 1.0),
          ],
        );

        final formatter = CsvFormatter(includeHeader: false);
        final result = formatter.format(transcript);
        expect(result.contains('"'), isFalse);
      });

      test('has correct file extension', () {
        final formatter = CsvFormatter();
        expect(formatter.fileExtension, equals('csv'));
      });

      test('has correct mime type', () {
        final formatter = CsvFormatter();
        expect(formatter.mimeType, equals('text/csv'));
      });
    });
  });
}
