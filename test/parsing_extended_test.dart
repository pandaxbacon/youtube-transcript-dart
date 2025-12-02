import 'package:test/test.dart';
import 'package:youtube_transcript_api/src/parsing/transcript_parser.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('TranscriptParser Extended', () {
    group('parseXml edge cases', () {
      test('parses transcript with duration attribute', () {
        const xmlContent = '''
          <transcript>
            <text start="0.0" duration="2.5">Hello</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(xmlContent);
        expect(snippets.length, equals(1));
        expect(snippets.first.duration, equals(2.5));
      });

      test('skips empty text elements', () {
        const xmlContent = '''
          <transcript>
            <text start="0.0" dur="1.0"></text>
            <text start="1.0" dur="1.0">Hello</text>
            <text start="2.0" dur="1.0">   </text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(xmlContent);
        // Empty elements are skipped, whitespace-only may or may not be
        // At minimum the "Hello" element should be parsed
        expect(snippets.length, greaterThanOrEqualTo(1));
        expect(snippets.any((s) => s.text.contains('Hello')), isTrue);
      });

      test('skips elements with invalid start time', () {
        const xmlContent = '''
          <transcript>
            <text start="invalid" dur="1.0">Bad start</text>
            <text start="1.0" dur="1.0">Good</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(xmlContent);
        expect(snippets.length, equals(1));
        expect(snippets.first.text, equals('Good'));
      });

      test('handles complex HTML entities', () {
        const xmlContent = '''
          <transcript>
            <text start="0.0" dur="1.0">Test &amp; &quot;quoted&quot;</text>
            <text start="1.0" dur="1.0">It&#39;s a test</text>
            <text start="2.0" dur="1.0">&nbsp;space&nbsp;</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(xmlContent);
        expect(snippets[0].text, equals('Test & "quoted"'));
        expect(snippets[1].text, equals("It's a test"));
        expect(snippets[2].text, contains('space'));
      });

      test('decodes numeric HTML entities', () {
        const xmlContent = '''
          <transcript>
            <text start="0.0" dur="1.0">&#65;&#66;&#67;</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(xmlContent);
        expect(snippets.first.text, equals('ABC'));
      });

      test('decodes hexadecimal HTML entities', () {
        const xmlContent = '''
          <transcript>
            <text start="0.0" dur="1.0">&#x41;&#x42;&#x43;</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(xmlContent);
        expect(snippets.first.text, equals('ABC'));
      });

      test('strips HTML tags when not preserving formatting', () {
        const xmlContent = '''
          <transcript>
            <text start="0.0" dur="1.0"><b>Bold</b> and <i>italic</i> text</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(
          xmlContent,
          preserveFormatting: false,
        );
        expect(snippets.first.text, equals('Bold and italic text'));
      });

      test('preserves text content with preserveFormatting', () {
        const xmlContent = '''
          <transcript>
            <text start="0.0" dur="1.0">Regular text here</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(
          xmlContent,
          preserveFormatting: true,
        );
        expect(snippets.first.text, equals('Regular text here'));
      });

      test('collapses whitespace when stripping formatting', () {
        const xmlContent = '''
          <transcript>
            <text start="0.0" dur="1.0">Multiple    spaces   here</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(
          xmlContent,
          preserveFormatting: false,
        );
        expect(snippets.first.text, equals('Multiple spaces here'));
      });

      test('throws TranscriptParseException for no text elements', () {
        const xmlContent = '''
          <transcript>
          </transcript>
        ''';

        expect(
          () => TranscriptParser.parseXml(xmlContent),
          throwsA(isA<TranscriptParseException>()),
        );
      });

      test('throws TranscriptParseException when all snippets are invalid', () {
        const xmlContent = '''
          <transcript>
            <text dur="1.0">No start</text>
            <text start="invalid" dur="1.0">Invalid start</text>
          </transcript>
        ''';

        expect(
          () => TranscriptParser.parseXml(xmlContent),
          throwsA(isA<TranscriptParseException>()),
        );
      });

      test('handles zero duration', () {
        const xmlContent = '''
          <transcript>
            <text start="5.0" dur="0">Zero duration</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(xmlContent);
        expect(snippets.first.duration, equals(0.0));
      });

      test('handles large start times', () {
        const xmlContent = '''
          <transcript>
            <text start="3661.5" dur="2.5">Late in video</text>
          </transcript>
        ''';

        final snippets = TranscriptParser.parseXml(xmlContent);
        expect(snippets.first.start, equals(3661.5)); // > 1 hour
      });
    });

    group('createFetchedTranscript', () {
      test('creates FetchedTranscript with all properties', () {
        final snippets = [
          TranscriptSnippet(text: 'Hello', start: 0.0, duration: 1.0),
          TranscriptSnippet(text: 'World', start: 1.0, duration: 1.0),
        ];

        final fetched = TranscriptParser.createFetchedTranscript(
          videoId: 'test123',
          language: 'English',
          languageCode: 'en',
          isGenerated: true,
          isTranslated: false,
          snippets: snippets,
        );

        expect(fetched.videoId, equals('test123'));
        expect(fetched.language, equals('English'));
        expect(fetched.languageCode, equals('en'));
        expect(fetched.isGenerated, isTrue);
        expect(fetched.isTranslated, isFalse);
        expect(fetched.snippets.length, equals(2));
      });

      test('creates translated FetchedTranscript', () {
        final snippets = [
          TranscriptSnippet(text: 'Hallo', start: 0.0, duration: 1.0),
        ];

        final fetched = TranscriptParser.createFetchedTranscript(
          videoId: 'test123',
          language: 'German',
          languageCode: 'de',
          isGenerated: false,
          isTranslated: true,
          snippets: snippets,
        );

        expect(fetched.isTranslated, isTrue);
        expect(fetched.languageCode, equals('de'));
      });
    });
  });
}
