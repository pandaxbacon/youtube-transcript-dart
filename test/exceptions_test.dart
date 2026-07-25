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
      expect(exception.toString(), contains('invalid video ID'));
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

    test('AgeRestrictedException formats correctly', () {
      final exception = AgeRestrictedException('test123');

      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('age-restricted'));
    });

    test('VideoUnplayableException with reason and subReasons', () {
      final exception = VideoUnplayableException(
        videoId: 'test123',
        reason: 'Copyright claim',
        subReasons: ['Music detected', 'Region locked'],
      );

      expect(exception.reason, equals('Copyright claim'));
      expect(exception.subReasons, equals(['Music detected', 'Region locked']));
      expect(exception.toString(), contains('Copyright claim'));
      expect(exception.toString(), contains('Music detected'));
      expect(exception.toString(), contains('Region locked'));
    });

    test('VideoUnplayableException without reason defaults', () {
      final exception = VideoUnplayableException(
        videoId: 'test123',
        subReasons: [],
      );

      expect(exception.reason, isNull);
      expect(exception.toString(), contains('unplayable'));
    });

    test('YouTubeRequestFailedException includes statusCode', () {
      final exception = YouTubeRequestFailedException(
        videoId: 'test123',
        statusCode: 500,
        responseBody: 'Internal Server Error',
      );

      expect(exception.statusCode, equals(500));
      expect(exception.responseBody, equals('Internal Server Error'));
      expect(exception.toString(), contains('HTTP 500'));
      expect(exception.toString(), contains('Internal Server Error'));
    });

    test('FailedToCreateConsentCookieException formats correctly', () {
      final exception = FailedToCreateConsentCookieException('test123');

      expect(exception.toString(), contains('consent'));
      expect(exception.toString(), contains('cookie'));
    });

    test('RequestBlockedException withProxyConfig shows Webshare guidance', () {
      final exception = RequestBlockedException('test123')
          .withProxyConfig(WebshareProxyConfig(username: 'u', password: 'p'));

      final msg = exception.toString();
      expect(msg, contains('Webshare'));
      expect(msg, contains('Residential'));
    });

    test('RequestBlockedException withProxyConfig shows generic proxy guidance',
        () {
      final exception = RequestBlockedException('test123')
          .withProxyConfig(GenericProxyConfig(httpUrl: 'http://proxy:8080'));

      final msg = exception.toString();
      expect(msg, contains('proxy'));
    });

    test('InvalidVideoIdException suggests using video ID not URL', () {
      final exception =
          InvalidVideoIdException('https://www.youtube.com/watch?v=1234');

      expect(exception.toString(), contains('video ID'));
      expect(exception.toString(), contains('NOT the URL'));
      expect(exception.toString(), contains('api.fetch("1234")'));
    });
  });
}
