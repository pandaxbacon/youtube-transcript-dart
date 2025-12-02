import 'package:test/test.dart';
import 'package:youtube_transcript_api/src/settings.dart';

void main() {
  group('Settings', () {
    test('watchUrl contains placeholder', () {
      expect(watchUrl, contains('{video_id}'));
    });

    test('watchUrl can be used for video URLs', () {
      final url = watchUrl.replaceAll('{video_id}', 'test123');
      expect(url, equals('https://www.youtube.com/watch?v=test123'));
    });

    test('innertubeApiUrl contains placeholder', () {
      expect(innertubeApiUrl, contains('{api_key}'));
    });

    test('innertubeApiUrl can be used for API requests', () {
      final url = innertubeApiUrl.replaceAll('{api_key}', 'AIzaSyTest');
      expect(
        url,
        equals('https://www.youtube.com/youtubei/v1/player?key=AIzaSyTest'),
      );
    });

    test('innertubeContext has required fields', () {
      expect(innertubeContext, containsPair('client', isNotNull));
      final client = innertubeContext['client'] as Map<String, dynamic>;
      expect(client, containsPair('clientName', 'ANDROID'));
      expect(client, containsPair('clientVersion', isNotEmpty));
    });

    test('innertubeApiKeyPattern matches valid API keys', () {
      const html =
          '"INNERTUBE_API_KEY":"AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"';
      final match = innertubeApiKeyPattern.firstMatch(html);
      expect(match, isNotNull);
      expect(
        match!.group(1),
        equals('AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8'),
      );
    });

    test(
      'innertubeApiKeyPattern matches keys with underscores and hyphens',
      () {
        const html = '"INNERTUBE_API_KEY":"test_key-123"';
        final match = innertubeApiKeyPattern.firstMatch(html);
        expect(match, isNotNull);
        expect(match!.group(1), equals('test_key-123'));
      },
    );

    test('innertubeApiKeyPattern handles whitespace', () {
      const html = '"INNERTUBE_API_KEY": "AIzaSyTest123"';
      final match = innertubeApiKeyPattern.firstMatch(html);
      expect(match, isNotNull);
      expect(match!.group(1), equals('AIzaSyTest123'));
    });

    test('innertubeApiKeyPattern does not match invalid keys', () {
      const html = '"INNERTUBE_API_KEY":""';
      final match = innertubeApiKeyPattern.firstMatch(html);
      // Empty string won't match the pattern [a-zA-Z0-9_-]+
      expect(match, isNull);
    });
  });
}
