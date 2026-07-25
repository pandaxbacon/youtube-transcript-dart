import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('PrettyPrintFormatter', () {
    final transcript = FetchedTranscript(
      videoId: 'test123',
      language: 'English',
      languageCode: 'en',
      isGenerated: false,
      isTranslated: false,
      snippets: [
        TranscriptSnippet(text: 'Hello world', start: 1.0, duration: 2.0),
        TranscriptSnippet(text: 'How are you', start: 3.0, duration: 1.5),
      ],
    );

    test('formats transcript as pretty JSON', () {
      final formatter = PrettyPrintFormatter();
      final result = formatter.format(transcript);

      expect(result, contains('"text"'));
      expect(result, contains('"Hello world"'));
      expect(result, contains('"start"'));
      expect(result, contains('\n')); // pretty-printed
    });

    test('non-pretty mode produces compact output', () {
      final formatter = PrettyPrintFormatter(pretty: false);
      final result = formatter.format(transcript);

      expect(result, contains('"text"'));
      expect(result, isNot(contains('  '))); // no indentation
    });

    test('formatAll formats multiple transcripts as JSON array', () {
      final formatter = PrettyPrintFormatter(pretty: false);
      final result = formatter.formatAll([transcript, transcript]);

      expect(result, startsWith('['));
      expect(result, endsWith(']'));
      // Should contain two entries
      final parsed = [
        for (final entry in result.split('},{')) entry,
      ];
      expect(parsed.length, greaterThanOrEqualTo(2));
    });

    test('fileExtension is json', () {
      expect(PrettyPrintFormatter().fileExtension, equals('json'));
    });

    test('mimeType is application/json', () {
      expect(PrettyPrintFormatter().mimeType, equals('application/json'));
    });

    test('toString describes formatter', () {
      expect(
        PrettyPrintFormatter().toString(),
        contains('PrettyPrintFormatter'),
      );
    });
  });

  group('FormatterLoader', () {
    test('loads all supported types', () {
      final types = FormatterLoader.supportedTypes;
      expect(
        types,
        containsAll(
          ['json', 'pretty', 'text', 'text-ts', 'webvtt', 'srt', 'csv'],
        ),
      );

      for (final type in types) {
        final formatter = FormatterLoader.load(type);
        expect(formatter, isA<TranscriptFormatter>());
      }
    });

    test('supportedTypes returns non-empty list', () {
      expect(FormatterLoader.supportedTypes, isNotEmpty);
    });

    test('load throws for unknown type', () {
      expect(
        () => FormatterLoader.load('unknown-format'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('load error message lists supported types', () {
      try {
        FormatterLoader.load('xyz');
        fail('Should have thrown');
      } on ArgumentError catch (e) {
        expect(e.toString(), contains('Choose one of'));
        expect(e.toString(), contains('json'));
        expect(e.toString(), contains('srt'));
      }
    });
  });

  group('TranscriptFormatterExtension', () {
    final transcript = FetchedTranscript(
      videoId: 'test123',
      language: 'English',
      languageCode: 'en',
      isGenerated: false,
      isTranslated: false,
      snippets: [
        TranscriptSnippet(text: 'Line 1', start: 0.0, duration: 1.0),
        TranscriptSnippet(text: 'Line 2', start: 1.0, duration: 1.0),
      ],
    );

    test('formatAll joins transcripts with newlines by default', () {
      final formatter = TextFormatter();
      final result = formatter.formatAll([transcript, transcript]);
      expect(result, contains('\n'));
      expect(result, contains('Line 1'));
    });
  });
}
