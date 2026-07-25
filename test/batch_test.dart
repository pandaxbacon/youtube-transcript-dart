import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

class _TestYouTubeTranscriptApi extends YouTubeTranscriptApi {
  _TestYouTubeTranscriptApi(this._fetchHandler)
      : super(
          httpClient: TranscriptHttpClient(
            customClient: MockClient((_) async => http.Response('', 200)),
          ),
        );

  final Future<FetchedTranscript> Function(String videoId) _fetchHandler;

  @override
  Future<FetchedTranscript> fetch(
    String videoId, {
    List<String>? languages,
    bool preserveFormatting = false,
  }) {
    return _fetchHandler(videoId);
  }
}

FetchedTranscript _sampleTranscript(String videoId) {
  return FetchedTranscript(
    videoId: videoId,
    language: 'English',
    languageCode: 'en',
    isGenerated: false,
    isTranslated: false,
    snippets: [TranscriptSnippet(start: 0, duration: 1, text: 'hello')],
  );
}

void main() {
  group('fetchBatch', () {
    test('returns empty result for empty input', () async {
      final api = YouTubeTranscriptApi();
      final progressCalls = <List<int>>[];

      final results = await api.fetchBatch(
        [],
        onProgress: (completed, total) {
          progressCalls.add([completed, total]);
        },
      );

      expect(results, isEmpty);
      expect(
        progressCalls,
        equals([
          [0, 0],
        ]),
      );
      api.dispose();
    });

    test('fetches multiple transcripts successfully', () async {
      final api = _TestYouTubeTranscriptApi(
        (videoId) async => _sampleTranscript(videoId),
      );
      addTearDown(api.dispose);

      final results = await api.fetchBatch(['AAAAAAAAAAA', 'BBBBBBBBBBB']);

      expect(results.length, 2);
      expect(results['AAAAAAAAAAA']!.isSuccess, isTrue);
      expect(results['BBBBBBBBBBB']!.isSuccess, isTrue);
    });

    test('continues on errors when configured', () async {
      final api = _TestYouTubeTranscriptApi((videoId) async {
        if (videoId == 'BBBBBBBBBBB') {
          throw TranscriptFetchException('failure', videoId: videoId);
        }
        return _sampleTranscript(videoId);
      });
      addTearDown(api.dispose);

      final results = await api.fetchBatch(
        [
          'AAAAAAAAAAA',
          'BBBBBBBBBBB',
          'CCCCCCCCCCC',
        ],
        continueOnError: true,
      );

      expect(results['AAAAAAAAAAA']!.isSuccess, isTrue);
      expect(results['CCCCCCCCCCC']!.isSuccess, isTrue);
      expect(results['BBBBBBBBBBB']!.isFailure, isTrue);
      expect(results['BBBBBBBBBBB']!.error, isA<TranscriptFetchException>());
    });

    test('throws when continueOnError is false', () async {
      final api = _TestYouTubeTranscriptApi((videoId) async {
        throw TranscriptFetchException('failure', videoId: videoId);
      });
      addTearDown(api.dispose);

      await expectLater(
        api.fetchBatch(['AAAAAAAAAAA', 'BBBBBBBBBBB'], continueOnError: false),
        throwsA(isA<TranscriptException>()),
      );
    });

    test('invokes progress callback', () async {
      final api = _TestYouTubeTranscriptApi(
        (videoId) async => _sampleTranscript(videoId),
      );
      addTearDown(api.dispose);
      final progress = <List<int>>[];

      await api.fetchBatch(
        [
          'AAAAAAAAAAA',
          'BBBBBBBBBBB',
        ],
        onProgress: (completed, total) => progress.add([completed, total]),
      );

      expect(
        progress,
        equals([
          [1, 2],
          [2, 2],
        ]),
      );
    });

    test('limits concurrency', () async {
      var active = 0;
      var maxActive = 0;
      final api = _TestYouTubeTranscriptApi((videoId) async {
        active++;
        maxActive = active > maxActive ? active : maxActive;
        await Future.delayed(const Duration(milliseconds: 100));
        active--;
        return _sampleTranscript(videoId);
      });
      addTearDown(api.dispose);

      final stopwatch = Stopwatch()..start();

      await api.fetchBatch(
        [
          'AAAAAAAAAAA',
          'BBBBBBBBBBB',
          'CCCCCCCCCCC',
        ],
        maxConcurrent: 2,
      );

      stopwatch.stop();

      expect(maxActive, lessThanOrEqualTo(2));
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(300));
    });

    test('handles invalid video IDs', () async {
      final api = _TestYouTubeTranscriptApi(
        (videoId) async => _sampleTranscript(videoId),
      );
      addTearDown(api.dispose);

      final results = await api.fetchBatch(['short', 'AAAAAAAAAAA']);

      expect(results['AAAAAAAAAAA']!.isSuccess, isTrue);
      expect(results['short']!.isFailure, isTrue);
      expect(results['short']!.error, isA<InvalidVideoIdException>());
    });
  });
}
