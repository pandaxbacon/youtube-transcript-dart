import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('Exceptions', () {
    test('TranscriptException includes video ID', () {
      final exception = TranscriptException('Test error', videoId: 'test123');

      expect(exception.message, equals('Test error'));
      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('test123'));
    });

    test('VideoUnavailableException formats correctly', () {
      final exception = VideoUnavailableException('test123');

      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('video is not available'));
    });

    test('TranscriptsDisabledException formats correctly', () {
      final exception = TranscriptsDisabledException('test123');

      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('disabled'));
    });

    test('NoTranscriptFoundException includes languages', () {
      final exception = NoTranscriptFoundException(
        videoId: 'test123',
        requestedLanguages: ['en', 'de'],
        availableLanguages: ['fr', 'es'],
      );

      expect(exception.requestedLanguages, equals(['en', 'de']));
      expect(exception.availableLanguages, equals(['fr', 'es']));
      expect(exception.toString(), contains('en, de'));
      expect(exception.toString(), contains('fr, es'));
    });

    test('TooManyRequestsException formats correctly', () {
      final exception = TooManyRequestsException('test123');

      expect(exception.toString(), contains('too many requests'));
    });

    test('RequestBlockedException includes status code', () {
      final exception = RequestBlockedException('test123', statusCode: 403);

      expect(exception.statusCode, equals(403));
      expect(exception.toString(), contains('403'));
    });

    test('IpBlockedException formats correctly', () {
      final exception = IpBlockedException('test123');

      expect(exception.toString(), contains('IP address'));
      expect(exception.toString(), contains('blocked'));
    });

    test('InvalidVideoIdException formats correctly', () {
      final exception = InvalidVideoIdException('bad-id');

      expect(exception.videoId, equals('bad-id'));
      expect(exception.toString(), contains('Invalid video ID'));
    });

    test('TranscriptFetchException includes cause', () {
      final cause = Exception('Original error');
      final exception = TranscriptFetchException(
        'Fetch failed',
        videoId: 'test123',
        cause: cause,
      );

      expect(exception.cause, equals(cause));
      expect(exception.toString(), contains('Caused by'));
    });
  });
}
