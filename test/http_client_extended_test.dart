import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('TranscriptHttpClient extended', () {
    test('WebshareProxyConfig defaults retriesWhenBlocked to 10', () {
      final config = WebshareProxyConfig(username: 'u', password: 'p');
      expect(config.retriesWhenBlocked, equals(10));
    });

    test('WebshareProxyConfig preventKeepingConnectionsAlive is true', () {
      final config = WebshareProxyConfig(username: 'u', password: 'p');
      expect(config.preventKeepingConnectionsAlive, isTrue);
    });

    test('GenericProxyConfig retriesWhenBlocked defaults to 0', () {
      final config = GenericProxyConfig(httpUrl: 'http://proxy:8080');
      expect(config.retriesWhenBlocked, equals(0));
    });

    test('GenericProxyConfig preventKeepingConnectionsAlive defaults to false',
        () {
      final config = GenericProxyConfig(httpUrl: 'http://proxy:8080');
      expect(config.preventKeepingConnectionsAlive, isFalse);
    });

    test('TranscriptHttpClient with Webshare proxy adds Connection: close', () {
      final config = WebshareProxyConfig(username: 'u', password: 'p');
      final client = TranscriptHttpClient(proxyConfig: config);
      expect(client.defaultHeaders['Connection'], equals('close'));
    });

    test('TranscriptHttpClient without proxy does not add Connection: close',
        () {
      final client = TranscriptHttpClient();
      expect(client.defaultHeaders['Connection'], isNull);
    });

    test(
        'TranscriptHttpClient with GenericProxyConfig does not add Connection: close',
        () {
      final config = GenericProxyConfig(httpUrl: 'http://proxy:8080');
      final client = TranscriptHttpClient(proxyConfig: config);
      expect(client.defaultHeaders['Connection'], isNull);
    });
  });
}
