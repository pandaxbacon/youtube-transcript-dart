import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('TranscriptHttpClient unit tests', () {
    test('creates with default values', () {
      final client = TranscriptHttpClient();
      expect(client.timeout.inSeconds, equals(30));
    });

    test('creates with custom timeout', () {
      final client = TranscriptHttpClient(timeout: Duration(seconds: 60));
      expect(client.timeout.inSeconds, equals(60));
    });

    test('creates with proxy config', () {
      final config = WebshareProxyConfig(username: 'u', password: 'p');
      final client = TranscriptHttpClient(proxyConfig: config);
      expect(client.proxyConfig, equals(config));
      expect(client.defaultHeaders['Connection'], equals('close'));
    });

    test('close does not throw without custom client', () {
      final client = TranscriptHttpClient();
      expect(() => client.close(), returnsNormally);
    });

    test('HttpResponse isSuccessful for 200', () {
      final response = HttpResponse(statusCode: 200, body: '', headers: {});
      expect(response.isSuccessful, isTrue);
    });

    test('HttpResponse isSuccessful false for 404', () {
      final response = HttpResponse(statusCode: 404, body: '', headers: {});
      expect(response.isSuccessful, isFalse);
    });

    test('HttpResponse stores status code and body', () {
      final response = HttpResponse(
        statusCode: 201,
        body: 'created',
        headers: {'X-Foo': 'bar'},
      );
      expect(response.statusCode, equals(201));
      expect(response.body, equals('created'));
      expect(response.headers['X-Foo'], equals('bar'));
    });

    test('setCookie does not throw', () {
      final client = TranscriptHttpClient();
      client.setCookie('TEST', 'value');
      // Just verify no exception
    });

    test('setCookie with domain does not throw', () {
      final client = TranscriptHttpClient();
      client.setCookie('TEST', 'value', domain: '.youtube.com');
      // Just verify no exception
    });
  });
}
