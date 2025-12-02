import 'package:test/test.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() {
  group('ProxyConfig', () {
    group('WebshareProxyConfig', () {
      test('creates with required parameters', () {
        final config = WebshareProxyConfig(username: 'user', password: 'pass');

        expect(config.username, equals('user'));
        expect(config.password, equals('pass'));
        expect(config.host, equals('p.webshare.io'));
        expect(config.port, equals(80));
        expect(config.location, isNull);
      });

      test('creates with custom host and port', () {
        final config = WebshareProxyConfig(
          username: 'user',
          password: 'pass',
          host: 'custom.proxy.io',
          port: 8080,
        );

        expect(config.host, equals('custom.proxy.io'));
        expect(config.port, equals(8080));
      });

      test('creates with location', () {
        final config = WebshareProxyConfig(
          username: 'user',
          password: 'pass',
          location: 'US',
        );

        expect(config.location, equals('US'));
      });

      test('getHttpProxyUrl returns correct format', () {
        final config = WebshareProxyConfig(username: 'user', password: 'pass');

        final url = config.getHttpProxyUrl();
        expect(url, equals('http://user:pass@p.webshare.io:80'));
      });

      test('getHttpsProxyUrl returns correct format', () {
        final config = WebshareProxyConfig(username: 'user', password: 'pass');

        final url = config.getHttpsProxyUrl();
        expect(url, equals('http://user:pass@p.webshare.io:80'));
      });

      test('getHttpProxyUrl includes location when set', () {
        final config = WebshareProxyConfig(
          username: 'user',
          password: 'pass',
          location: 'US',
        );

        final url = config.getHttpProxyUrl();
        expect(url, contains('-country-US'));
      });

      test('getHeaders returns empty map', () {
        final config = WebshareProxyConfig(username: 'user', password: 'pass');

        expect(config.getHeaders(), isEmpty);
      });

      test('toString returns expected format', () {
        final config = WebshareProxyConfig(
          username: 'user',
          password: 'pass',
          location: 'US',
        );

        final str = config.toString();
        expect(str, contains('WebshareProxyConfig'));
        expect(str, contains('user'));
        expect(str, contains('US'));
      });
    });

    group('GenericProxyConfig', () {
      test('creates with httpUrl', () {
        final config = GenericProxyConfig(
          httpUrl: 'http://proxy.example.com:8080',
        );

        expect(
          config.getHttpProxyUrl(),
          equals('http://proxy.example.com:8080'),
        );
        expect(config.getHttpsProxyUrl(), isNull);
      });

      test('creates with httpsUrl', () {
        final config = GenericProxyConfig(
          httpsUrl: 'https://proxy.example.com:8443',
        );

        expect(config.getHttpProxyUrl(), isNull);
        expect(
          config.getHttpsProxyUrl(),
          equals('https://proxy.example.com:8443'),
        );
      });

      test('creates with both URLs', () {
        final config = GenericProxyConfig(
          httpUrl: 'http://proxy.example.com:8080',
          httpsUrl: 'https://proxy.example.com:8443',
        );

        expect(
          config.getHttpProxyUrl(),
          equals('http://proxy.example.com:8080'),
        );
        expect(
          config.getHttpsProxyUrl(),
          equals('https://proxy.example.com:8443'),
        );
      });

      test('throws when neither URL provided', () {
        expect(() => GenericProxyConfig(), throwsA(isA<ArgumentError>()));
      });

      test('getHeaders returns empty by default', () {
        final config = GenericProxyConfig(
          httpUrl: 'http://proxy.example.com:8080',
        );

        expect(config.getHeaders(), isEmpty);
      });

      test('getHeaders returns custom headers', () {
        final config = GenericProxyConfig(
          httpUrl: 'http://proxy.example.com:8080',
          customHeaders: {'X-Custom-Header': 'value'},
        );

        expect(config.getHeaders()['X-Custom-Header'], equals('value'));
      });

      test('toString returns expected format', () {
        final config = GenericProxyConfig(
          httpUrl: 'http://proxy.example.com:8080',
          httpsUrl: 'https://proxy.example.com:8443',
        );

        final str = config.toString();
        expect(str, contains('GenericProxyConfig'));
        expect(str, contains('http://proxy.example.com:8080'));
        expect(str, contains('https://proxy.example.com:8443'));
      });
    });
  });
}
