import 'dart:io';
import 'package:test/test.dart';
import 'package:youtube_transcript_api/src/parsing/transcript_parser.dart';

/// Tests that use real captured YouTube responses as fixtures.
/// This tests the parsing logic with actual YouTube data.
void main() {
  group('Fixture Parsing Tests', () {
    test('parses real YouTube transcript XML from fixture', () async {
      // Load the real transcript XML captured from YouTube
      final transcriptXml = await File(
        'test/fixtures/transcript.xml',
      ).readAsString();

      // Parse it using the REAL parser code
      final snippets = TranscriptParser.parseXml(transcriptXml);

      // Verify it parsed correctly
      expect(snippets, isNotEmpty);
      expect(snippets.length, greaterThan(50));

      // Check first snippet
      final first = snippets.first;
      expect(first.text, contains('citizens'));
      expect(first.start, closeTo(0.56, 0.01));
      expect(first.duration, greaterThan(0));

      // Verify all snippets have required fields
      for (var snippet in snippets) {
        expect(snippet.text, isNotEmpty);
        expect(snippet.start, greaterThanOrEqualTo(0));
        expect(snippet.duration, greaterThanOrEqualTo(0));
      }

      print('✅ Parsed ${snippets.length} snippets from real YouTube XML');
    });

    test('parses real transcript with HTML entities', () async {
      final transcriptXml = await File(
        'test/fixtures/transcript.xml',
      ).readAsString();

      final snippets = TranscriptParser.parseXml(transcriptXml);

      // The real transcript has HTML entities like &#39;
      var found = false;
      for (var snippet in snippets) {
        if (snippet.text.contains("'") || snippet.text.contains('&')) {
          found = true;
          // Verify HTML entities were decoded
          expect(snippet.text, isNot(contains('&#39;')));
          expect(snippet.text, isNot(contains('&amp;')));
        }
      }

      // The fixture should have some entities that got decoded
      expect(found, isTrue, reason: 'Should have decoded some HTML entities');
    });
  });
}
