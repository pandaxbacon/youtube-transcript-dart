import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('Additional Exception Tests', () {
    test('TranscriptException without videoId', () {
      final exception = TranscriptException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.videoId, isNull);
      expect(exception.toString(), equals('TranscriptException: Test error'));
    });

    test('NoTranscriptManuallyCreatedException toString', () {
      final exception = NoTranscriptManuallyCreatedException(
        videoId: 'test123',
        requestedLanguages: ['en', 'de'],
        availableLanguages: ['fr'],
      );

      final str = exception.toString();
      expect(str, contains('NoTranscriptManuallyCreatedException'));
      expect(str, contains('manually created'));
      expect(str, contains('en, de'));
      expect(str, contains('fr'));
      expect(str, contains('test123'));
    });

    test('NoTranscriptGeneratedException toString', () {
      final exception = NoTranscriptGeneratedException(
        videoId: 'test123',
        requestedLanguages: ['en', 'de'],
        availableLanguages: ['fr'],
      );

      final str = exception.toString();
      expect(str, contains('NoTranscriptGeneratedException'));
      expect(str, contains('auto-generated'));
      expect(str, contains('en, de'));
      expect(str, contains('fr'));
      expect(str, contains('test123'));
    });

    test('TranslationNotAvailableException', () {
      final exception = TranslationNotAvailableException(
        videoId: 'test123',
        targetLanguage: 'de',
      );

      expect(exception.targetLanguage, equals('de'));
      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('Translation'));
      expect(exception.toString(), contains('de'));
    });

    test('TooManyRequestsException', () {
      final exception = TooManyRequestsException('test123');
      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('too many requests'));
      expect(exception.toString(), contains('IP'));
    });

    test('RequestBlockedException without statusCode', () {
      final exception = RequestBlockedException('test123');
      expect(exception.statusCode, isNull);
      expect(exception.toString(), contains('blocked'));
      expect(exception.toString(), isNot(contains('HTTP')));
    });

    test('IpBlockedException', () {
      final exception = IpBlockedException('test123');
      final str = exception.toString();
      expect(str, contains('IpBlockedException'));
      expect(str, contains('IP address'));
      expect(str, contains('blocked'));
      expect(str, contains('proxy'));
    });

    test('IpBlockedException with statusCode', () {
      final exception = IpBlockedException('test123', statusCode: 403);
      expect(exception.statusCode, equals(403));
    });

    test('InvalidVideoIdException', () {
      final exception = InvalidVideoIdException('invalid-id');
      expect(exception.videoId, equals('invalid-id'));
      expect(exception.toString(), contains('Invalid video ID'));
    });

    test('TranscriptFetchException without cause', () {
      final exception = TranscriptFetchException(
        'Fetch failed',
        videoId: 'test123',
      );

      expect(exception.cause, isNull);
      final str = exception.toString();
      expect(str, contains('Fetch failed'));
      expect(str, contains('test123'));
      expect(str, isNot(contains('Caused by')));
    });

    test('TranscriptParseException without cause', () {
      final exception = TranscriptParseException(
        'Parse failed',
        videoId: 'test123',
      );

      expect(exception.cause, isNull);
      final str = exception.toString();
      expect(str, contains('Parse failed'));
      expect(str, contains('test123'));
      expect(str, isNot(contains('Caused by')));
    });

    test('TranscriptParseException with cause', () {
      final cause = Exception('Root cause');
      final exception = TranscriptParseException(
        'Parse failed',
        videoId: 'test123',
        cause: cause,
      );

      expect(exception.cause, equals(cause));
      final str = exception.toString();
      expect(str, contains('Caused by'));
    });

    test('InvalidCookiesException', () {
      final exception = InvalidCookiesException('test123');
      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('cookies'));
      expect(exception.toString(), contains('invalid'));
    });

    test('PoTokenRequiredException', () {
      final exception = PoTokenRequiredException('test123');
      expect(exception.videoId, equals('test123'));
      final str = exception.toString();
      expect(str, contains('PoToken'));
      expect(str, contains('anti-bot'));
    });

    test('TranscriptsDisabledException', () {
      final exception = TranscriptsDisabledException('test123');
      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('disabled'));
    });

    test('VideoUnavailableException', () {
      final exception = VideoUnavailableException('test123');
      expect(exception.videoId, equals('test123'));
      expect(exception.toString(), contains('not available'));
    });
  });
}
