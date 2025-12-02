import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:youtube_transcript_api/src/parsing/transcript_list_parser.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('TranscriptListParser', () {
    // Mock fetch function for testing
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
        snippets: [TranscriptSnippet(text: 'Hello', start: 0.0, duration: 1.0)],
      );
    }

    group('extractCaptionsJson', () {
      test('extracts captions from ytInitialPlayerResponse', () {
        const html = '''
        <html>
        <script>
        var ytInitialPlayerResponse = {
          "captions": {
            "playerCaptionsTracklistRenderer": {
              "captionTracks": [{"languageCode": "en"}]
            }
          }
        };
        </script>
        </html>
        ''';

        final result = TranscriptListParser.extractCaptionsJson(html);
        expect(result, isNotNull);
      });

      test('returns null for HTML without captions', () {
        const html = '''
        <html><body>No captions here</body></html>
        ''';

        final result = TranscriptListParser.extractCaptionsJson(html);
        expect(result, isNull);
      });

      test('returns null for invalid JSON', () {
        const html = '''
        <html>
        <script>
        var ytInitialPlayerResponse = {invalid json};
        </script>
        </html>
        ''';

        final result = TranscriptListParser.extractCaptionsJson(html);
        expect(result, isNull);
      });
    });

    group('parse', () {
      test('parses captionTracks from InnerTube response', () async {
        // Load real fixture
        final fixtureContent = await File(
          'test/fixtures/innertube_response.json',
        ).readAsString();
        final data = json.decode(fixtureContent) as Map<String, dynamic>;

        // Extract the captions renderer
        final captions = data['captions'] as Map<String, dynamic>;
        final captionsRenderer =
            captions['playerCaptionsTracklistRenderer'] as Map<String, dynamic>;

        final result = TranscriptListParser.parse(
          videoId: 'eF8Qqp7rjDg',
          captionsJson: captionsRenderer,
          fetchFunction: mockFetch,
        );

        expect(result, isNotNull);
        expect(result.videoId, equals('eF8Qqp7rjDg'));
        expect(result.transcripts.isNotEmpty, isTrue);
      });

      test('throws TranscriptsDisabledException for empty captionTracks', () {
        final captionsJson = {'captionTracks': <dynamic>[]};

        expect(
          () => TranscriptListParser.parse(
            videoId: 'test123',
            captionsJson: captionsJson,
            fetchFunction: mockFetch,
          ),
          throwsA(isA<TranscriptsDisabledException>()),
        );
      });

      test('throws TranscriptsDisabledException for null captionTracks', () {
        final captionsJson = <String, dynamic>{};

        expect(
          () => TranscriptListParser.parse(
            videoId: 'test123',
            captionsJson: captionsJson,
            fetchFunction: mockFetch,
          ),
          throwsA(isA<TranscriptsDisabledException>()),
        );
      });

      test('parses manually created transcript', () {
        final captionsJson = {
          'captionTracks': [
            {
              'baseUrl': 'https://www.youtube.com/api/timedtext?lang=en',
              'languageCode': 'en',
              'name': {
                'runs': [
                  {'text': 'English'},
                ],
              },
              'kind': 'manual',
              'isTranslatable': true,
            },
          ],
          'translationLanguages': [
            {
              'languageCode': 'de',
              'languageName': {
                'runs': [
                  {'text': 'German'},
                ],
              },
            },
          ],
        };

        final result = TranscriptListParser.parse(
          videoId: 'test123',
          captionsJson: captionsJson,
          fetchFunction: mockFetch,
        );

        expect(result.transcripts.length, equals(1));
        final transcript = result.transcripts.first;
        expect(transcript.languageCode, equals('en'));
        expect(transcript.language, equals('English'));
        expect(transcript.isGenerated, isFalse);
        expect(transcript.isTranslatable, isTrue);
        expect(transcript.translationLanguages.length, equals(1));
      });

      test('parses auto-generated transcript', () {
        final captionsJson = {
          'captionTracks': [
            {
              'baseUrl': 'https://www.youtube.com/api/timedtext?lang=en',
              'languageCode': 'en',
              'name': {
                'runs': [
                  {'text': 'English (auto-generated)'},
                ],
              },
              'kind': 'asr',
              'isTranslatable': false,
            },
          ],
        };

        final result = TranscriptListParser.parse(
          videoId: 'test123',
          captionsJson: captionsJson,
          fetchFunction: mockFetch,
        );

        expect(result.transcripts.length, equals(1));
        final transcript = result.transcripts.first;
        expect(transcript.isGenerated, isTrue);
        expect(transcript.isTranslatable, isFalse);
      });

      test('removes fmt=srv3 from URL', () {
        final captionsJson = {
          'captionTracks': [
            {
              'baseUrl':
                  'https://www.youtube.com/api/timedtext?lang=en&fmt=srv3',
              'languageCode': 'en',
              'name': {
                'runs': [
                  {'text': 'English'},
                ],
              },
            },
          ],
        };

        final result = TranscriptListParser.parse(
          videoId: 'test123',
          captionsJson: captionsJson,
          fetchFunction: mockFetch,
        );

        expect(
          result.transcripts.first.transcriptUrl!.contains('&fmt=srv3'),
          isFalse,
        );
      });

      test('handles missing language name gracefully', () {
        final captionsJson = {
          'captionTracks': [
            {
              'baseUrl': 'https://www.youtube.com/api/timedtext?lang=en',
              'languageCode': 'en',
              // No 'name' field
            },
          ],
        };

        final result = TranscriptListParser.parse(
          videoId: 'test123',
          captionsJson: captionsJson,
          fetchFunction: mockFetch,
        );

        expect(result.transcripts.length, equals(1));
        expect(
          result.transcripts.first.language,
          equals('en'),
        ); // Falls back to languageCode
      });

      test('handles malformed caption track entries', () {
        final captionsJson = {
          'captionTracks': [
            'not a map', // Invalid entry
            {
              'baseUrl': 'https://www.youtube.com/api/timedtext?lang=en',
              'languageCode': 'en',
            },
            {
              // Missing baseUrl
              'languageCode': 'de',
            },
            {
              'baseUrl': 'https://www.youtube.com/api/timedtext?lang=fr',
              // Missing languageCode
            },
          ],
        };

        final result = TranscriptListParser.parse(
          videoId: 'test123',
          captionsJson: captionsJson,
          fetchFunction: mockFetch,
        );

        // Should only parse the valid entry
        expect(result.transcripts.length, equals(1));
        expect(result.transcripts.first.languageCode, equals('en'));
      });

      test('parses multiple transcripts', () {
        final captionsJson = {
          'captionTracks': [
            {
              'baseUrl': 'https://www.youtube.com/api/timedtext?lang=en',
              'languageCode': 'en',
              'name': {
                'runs': [
                  {'text': 'English'},
                ],
              },
            },
            {
              'baseUrl': 'https://www.youtube.com/api/timedtext?lang=de',
              'languageCode': 'de',
              'name': {
                'runs': [
                  {'text': 'German'},
                ],
              },
            },
            {
              'baseUrl': 'https://www.youtube.com/api/timedtext?lang=en',
              'languageCode': 'en',
              'kind': 'asr',
              'name': {
                'runs': [
                  {'text': 'English (auto-generated)'},
                ],
              },
            },
          ],
        };

        final result = TranscriptListParser.parse(
          videoId: 'test123',
          captionsJson: captionsJson,
          fetchFunction: mockFetch,
        );

        expect(result.transcripts.length, equals(3));
      });
    });
  });
}
