import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('YouTubeTranscriptApi', () {
    test('creates with default settings', () {
      final api = YouTubeTranscriptApi();
      expect(api, isNotNull);
      api.dispose();
    });

    test('creates with custom timeout', () {
      final api = YouTubeTranscriptApi(timeout: const Duration(seconds: 60));
      expect(api, isNotNull);
      api.dispose();
    });

    test('creates with proxy config', () {
      final api = YouTubeTranscriptApi(
        proxyConfig: WebshareProxyConfig(username: 'user', password: 'pass'),
      );
      expect(api, isNotNull);
      api.dispose();
    });

    test('creates with custom headers', () {
      final api = YouTubeTranscriptApi(headers: {'X-Custom': 'value'});
      expect(api, isNotNull);
      api.dispose();
    });

    group('video ID validation', () {
      test('throws InvalidVideoIdException for empty video ID', () async {
        final api = YouTubeTranscriptApi();

        expect(() => api.list(''), throwsA(isA<InvalidVideoIdException>()));

        api.dispose();
      });

      test('throws InvalidVideoIdException for short video ID', () async {
        final api = YouTubeTranscriptApi();

        expect(() => api.list('abc'), throwsA(isA<InvalidVideoIdException>()));

        api.dispose();
      });

      test('throws InvalidVideoIdException for long video ID', () async {
        final api = YouTubeTranscriptApi();

        expect(
          () => api.list('abcdefghijklmn'),
          throwsA(isA<InvalidVideoIdException>()),
        );

        api.dispose();
      });

      test('throws InvalidVideoIdException for invalid characters', () async {
        final api = YouTubeTranscriptApi();

        expect(
          () => api.list('abc!def@ghi'),
          throwsA(isA<InvalidVideoIdException>()),
        );

        api.dispose();
      });
    });

    group('HTTP error handling', () {
      test('throws TooManyRequestsException on 429 response', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Too many requests', 429);
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<TooManyRequestsException>()),
        );

        api.dispose();
      });

      test('throws IpBlockedException on 403 response', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Forbidden', 403);
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<IpBlockedException>()),
        );

        api.dispose();
      });

      test('throws VideoUnavailableException on 404 response', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not found', 404);
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<VideoUnavailableException>()),
        );

        api.dispose();
      });

      test('throws TranscriptFetchException on 500 response', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Server error', 500);
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<TranscriptFetchException>()),
        );

        api.dispose();
      });

      test('throws IpBlockedException when reCAPTCHA detected', () async {
        final mockClient = MockClient((request) async {
          return http.Response('<html>class="g-recaptcha"</html>', 200);
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<IpBlockedException>()),
        );

        api.dispose();
      });

      test('throws TranscriptFetchException when no API key found', () async {
        final mockClient = MockClient((request) async {
          return http.Response('<html>No API key here</html>', 200);
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<TranscriptFetchException>()),
        );

        api.dispose();
      });
    });

    group('Playability status handling', () {
      test('throws TranscriptsDisabledException when no captions', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<TranscriptsDisabledException>()),
        );

        api.dispose();
      });

      test(
        'throws TranscriptParseException for invalid JSON response',
        () async {
          var requestCount = 0;
          final mockClient = MockClient((request) async {
            requestCount++;
            if (requestCount == 1) {
              return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
            } else {
              return http.Response('not valid json', 200);
            }
          });

          final httpClient = TranscriptHttpClient(customClient: mockClient);
          final api = YouTubeTranscriptApi(httpClient: httpClient);

          await expectLater(
            () async => await api.list('dQw4w9WgXcQ'),
            throwsA(isA<TranscriptParseException>()),
          );

          api.dispose();
        },
      );

      test('throws RequestBlockedException for bot detection', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {
                  'status': 'LOGIN_REQUIRED',
                  'reason': 'Sign in to confirm you are not a bot',
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<RequestBlockedException>()),
        );

        api.dispose();
      });

      test('throws VideoUnavailableException for age restricted', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {
                  'status': 'LOGIN_REQUIRED',
                  'reason': 'This video may be inappropriate for some users',
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<VideoUnavailableException>()),
        );

        api.dispose();
      });

      test('throws VideoUnavailableException for unavailable video', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {
                  'status': 'ERROR',
                  'reason': 'Video unavailable',
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<VideoUnavailableException>()),
        );

        api.dispose();
      });

      test('throws TranscriptsDisabledException for empty captions', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
                'captions': {
                  'playerCaptionsTracklistRenderer': {'captionTracks': []},
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.list('dQw4w9WgXcQ'),
          throwsA(isA<TranscriptsDisabledException>()),
        );

        api.dispose();
      });

      test(
        'throws TranscriptFetchException for other playability errors',
        () async {
          var requestCount = 0;
          final mockClient = MockClient((request) async {
            requestCount++;
            if (requestCount == 1) {
              return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
            } else {
              return http.Response(
                json.encode({
                  'playabilityStatus': {
                    'status': 'UNPLAYABLE',
                    'reason': 'Some other error',
                  },
                }),
                200,
              );
            }
          });

          final httpClient = TranscriptHttpClient(customClient: mockClient);
          final api = YouTubeTranscriptApi(httpClient: httpClient);

          await expectLater(
            () async => await api.list('dQw4w9WgXcQ'),
            throwsA(isA<TranscriptFetchException>()),
          );

          api.dispose();
        },
      );
    });

    group('API with inline mock response', () {
      test('list returns TranscriptList', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"AIzaSyAO_test123"', 200);
          } else {
            // Minimal valid captions response
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
                'captions': {
                  'playerCaptionsTracklistRenderer': {
                    'captionTracks': [
                      {
                        'baseUrl':
                            'https://www.youtube.com/api/timedtext?lang=en',
                        'languageCode': 'en',
                        'name': {
                          'runs': [
                            {'text': 'English'},
                          ],
                        },
                        'kind': 'asr',
                        'isTranslatable': false,
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        final transcriptList = await api.list('dQw4w9WgXcQ');

        expect(transcriptList, isNotNull);
        expect(transcriptList.videoId, equals('dQw4w9WgXcQ'));
        expect(transcriptList.transcripts.isNotEmpty, isTrue);

        api.dispose();
      });

      test('findTranscript returns Transcript', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
                'captions': {
                  'playerCaptionsTracklistRenderer': {
                    'captionTracks': [
                      {
                        'baseUrl':
                            'https://www.youtube.com/api/timedtext?lang=en',
                        'languageCode': 'en',
                        'name': {
                          'runs': [
                            {'text': 'English'},
                          ],
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        final transcript = await api.findTranscript('dQw4w9WgXcQ', ['en']);
        expect(transcript, isNotNull);

        api.dispose();
      });

      test('fetch returns FetchedTranscript', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else if (requestCount == 2) {
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
                'captions': {
                  'playerCaptionsTracklistRenderer': {
                    'captionTracks': [
                      {
                        'baseUrl':
                            'https://www.youtube.com/api/timedtext?lang=en',
                        'languageCode': 'en',
                        'name': {
                          'runs': [
                            {'text': 'English'},
                          ],
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          } else {
            return http.Response(
              '<?xml version="1.0" encoding="utf-8" ?><transcript><text start="0.0" dur="2.0">Hello world</text></transcript>',
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        final fetchedTranscript = await api.fetch(
          'dQw4w9WgXcQ',
          languages: ['en'],
        );

        expect(fetchedTranscript, isNotNull);
        expect(fetchedTranscript.snippets.isNotEmpty, isTrue);

        api.dispose();
      });

      test('fetch uses default language en', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else if (requestCount == 2) {
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
                'captions': {
                  'playerCaptionsTracklistRenderer': {
                    'captionTracks': [
                      {
                        'baseUrl':
                            'https://www.youtube.com/api/timedtext?lang=en',
                        'languageCode': 'en',
                        'name': {
                          'runs': [
                            {'text': 'English'},
                          ],
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          } else {
            return http.Response(
              '<?xml version="1.0" encoding="utf-8" ?><transcript><text start="0.0" dur="2.0">Hello</text></transcript>',
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        final fetchedTranscript = await api.fetch('dQw4w9WgXcQ');

        expect(fetchedTranscript, isNotNull);

        api.dispose();
      });

      test('throws NoTranscriptFoundException for missing language', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
                'captions': {
                  'playerCaptionsTracklistRenderer': {
                    'captionTracks': [
                      {
                        'baseUrl':
                            'https://www.youtube.com/api/timedtext?lang=en',
                        'languageCode': 'en',
                        'name': {
                          'runs': [
                            {'text': 'English'},
                          ],
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        await expectLater(
          () async => await api.fetch('dQw4w9WgXcQ', languages: ['xyz']),
          throwsA(isA<NoTranscriptFoundException>()),
        );

        api.dispose();
      });

      test('findManuallyCreatedTranscript works correctly', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
                'captions': {
                  'playerCaptionsTracklistRenderer': {
                    'captionTracks': [
                      {
                        'baseUrl':
                            'https://www.youtube.com/api/timedtext?lang=en',
                        'languageCode': 'en',
                        'name': {
                          'runs': [
                            {'text': 'English'},
                          ],
                        },
                        'kind': 'manual',
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        final transcript = await api.findManuallyCreatedTranscript(
          'dQw4w9WgXcQ',
          ['en'],
        );
        expect(transcript, isNotNull);
        expect(transcript.isGenerated, isFalse);

        api.dispose();
      });

      test('findGeneratedTranscript works correctly', () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response('"INNERTUBE_API_KEY":"test123"', 200);
          } else {
            return http.Response(
              json.encode({
                'playabilityStatus': {'status': 'OK'},
                'captions': {
                  'playerCaptionsTracklistRenderer': {
                    'captionTracks': [
                      {
                        'baseUrl':
                            'https://www.youtube.com/api/timedtext?lang=en',
                        'languageCode': 'en',
                        'name': {
                          'runs': [
                            {'text': 'English (auto-generated)'},
                          ],
                        },
                        'kind': 'asr',
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
        });

        final httpClient = TranscriptHttpClient(customClient: mockClient);
        final api = YouTubeTranscriptApi(httpClient: httpClient);

        final transcript = await api.findGeneratedTranscript('dQw4w9WgXcQ', [
          'en',
        ]);
        expect(transcript, isNotNull);
        expect(transcript.isGenerated, isTrue);

        api.dispose();
      });
    });
  });
}
