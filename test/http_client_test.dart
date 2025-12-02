import 'package:test/test.dart';
import 'package:youtube_transcript_api/src/http/http_client.dart';

void main() {
  group('HttpResponse', () {
    test('creates response correctly', () {
      final response = HttpResponse(
        statusCode: 200,
        body: 'Hello World',
        headers: {'content-type': 'text/plain'},
      );

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Hello World'));
      expect(response.headers['content-type'], equals('text/plain'));
    });

    test('isSuccessful returns true for 2xx status codes', () {
      expect(
        HttpResponse(statusCode: 200, body: '', headers: {}).isSuccessful,
        isTrue,
      );
      expect(
        HttpResponse(statusCode: 201, body: '', headers: {}).isSuccessful,
        isTrue,
      );
      expect(
        HttpResponse(statusCode: 204, body: '', headers: {}).isSuccessful,
        isTrue,
      );
      expect(
        HttpResponse(statusCode: 299, body: '', headers: {}).isSuccessful,
        isTrue,
      );
    });

    test('isSuccessful returns false for non-2xx status codes', () {
      expect(
        HttpResponse(statusCode: 100, body: '', headers: {}).isSuccessful,
        isFalse,
      );
      expect(
        HttpResponse(statusCode: 199, body: '', headers: {}).isSuccessful,
        isFalse,
      );
      expect(
        HttpResponse(statusCode: 300, body: '', headers: {}).isSuccessful,
        isFalse,
      );
      expect(
        HttpResponse(statusCode: 400, body: '', headers: {}).isSuccessful,
        isFalse,
      );
      expect(
        HttpResponse(statusCode: 404, body: '', headers: {}).isSuccessful,
        isFalse,
      );
      expect(
        HttpResponse(statusCode: 500, body: '', headers: {}).isSuccessful,
        isFalse,
      );
    });
  });

  group('TranscriptHttpClient', () {
    test('creates with default settings', () {
      final client = TranscriptHttpClient();

      expect(client.proxyConfig, isNull);
      expect(client.defaultHeaders, isNotEmpty);
      expect(client.defaultHeaders['User-Agent'], isNotNull);
      expect(client.defaultHeaders['Accept-Language'], isNotNull);
      expect(client.timeout, equals(const Duration(seconds: 30)));
    });

    test('creates with custom headers', () {
      final client = TranscriptHttpClient(
        defaultHeaders: {'X-Custom-Header': 'value'},
      );

      expect(client.defaultHeaders['X-Custom-Header'], equals('value'));
      // Default headers should still be present
      expect(client.defaultHeaders['User-Agent'], isNotNull);
    });

    test('creates with custom timeout', () {
      final client = TranscriptHttpClient(timeout: const Duration(seconds: 60));

      expect(client.timeout, equals(const Duration(seconds: 60)));
    });

    test('close does not throw', () {
      final client = TranscriptHttpClient();
      expect(() => client.close(), returnsNormally);
    });
  });
}
