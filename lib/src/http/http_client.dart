import 'dart:convert';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'proxy_config.dart';

/// HTTP response wrapper.
class HttpResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  HttpResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}

/// HTTP client for making requests to YouTube.
///
/// Supports proxy configuration, cookie storage, and custom headers.
class TranscriptHttpClient {
  final ProxyConfig? proxyConfig;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final http.Client? _customClient;

  /// Stored cookies keyed by domain.
  final Map<String, String> _cookies = {};

  /// Creates a new HTTP client.
  ///
  /// [proxyConfig] - Optional proxy configuration.
  /// [defaultHeaders] - Headers to include in all requests.
  /// [timeout] - Request timeout duration.
  /// [customClient] - Optional custom HTTP client for testing.
  TranscriptHttpClient({
    this.proxyConfig,
    Map<String, String>? defaultHeaders,
    this.timeout = const Duration(seconds: 30),
    http.Client? customClient,
  })  : defaultHeaders = {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
          if (proxyConfig?.preventKeepingConnectionsAlive == true)
            'Connection': 'close',
          ...?defaultHeaders,
        },
        _customClient = customClient;

  /// Makes a POST request to the specified URL.
  Future<HttpResponse> post(
    String url, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (proxyConfig != null) ...proxyConfig!.getHeaders(),
      ...?headers,
    };

    // Add stored cookies
    final cookieHeader = _buildCookieHeader(url);
    if (cookieHeader != null) {
      mergedHeaders['Cookie'] = cookieHeader;
    }

    http.Response response;

    try {
      if (_customClient != null) {
        response = await _executeWithRetry(
          () => _customClient!
              .post(Uri.parse(url), headers: mergedHeaders, body: body)
              .timeout(timeout),
        );
      } else if (proxyConfig != null) {
        response = await _executeWithRetry(
          () => _makeProxiedRequest(
            url,
            mergedHeaders,
            method: 'POST',
            body: body,
          ),
        );
      } else {
        response = await _executeWithRetry(
          () => http
              .post(Uri.parse(url), headers: mergedHeaders, body: body)
              .timeout(timeout),
        );
      }

      _storeCookiesFromResponse(response.headers['set-cookie']);

      return HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on io.SocketException catch (e) {
      throw io.HttpException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw io.HttpException('HTTP client error: ${e.message}');
    } catch (e) {
      throw io.HttpException('Request failed: $e');
    }
  }

  /// Makes a GET request to the specified URL.
  Future<HttpResponse> get(String url, {Map<String, String>? headers}) async {
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (proxyConfig != null) ...proxyConfig!.getHeaders(),
      ...?headers,
    };

    // Add stored cookies
    final cookieHeader = _buildCookieHeader(url);
    if (cookieHeader != null) {
      mergedHeaders['Cookie'] = cookieHeader;
    }

    http.Response response;

    try {
      if (_customClient != null) {
        response = await _executeWithRetry(
          () => _customClient!
              .get(Uri.parse(url), headers: mergedHeaders)
              .timeout(timeout),
        );
      } else if (proxyConfig != null) {
        response = await _executeWithRetry(
          () => _makeProxiedRequest(url, mergedHeaders, method: 'GET'),
        );
      } else {
        response = await _executeWithRetry(
          () =>
              http.get(Uri.parse(url), headers: mergedHeaders).timeout(timeout),
        );
      }
      _storeCookiesFromResponse(response.headers['set-cookie']);

      return HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on io.SocketException catch (e) {
      throw io.HttpException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw io.HttpException('HTTP client error: ${e.message}');
    } catch (e) {
      throw io.HttpException('Request failed: $e');
    }
  }

  /// Makes a request using the configured proxy.
  ///
  /// Note: Full proxy support in Dart's http package is limited.
  /// For production use, you may need to use platform-specific implementations
  /// or the dart:io HttpClient with proxy configuration.
  Future<http.Response> _makeProxiedRequest(
    String url,
    Map<String, String> headers, {
    required String method,
    String? body,
  }) async {
    // For better proxy support, we use dart:io HttpClient
    // which allows proxy configuration via environment variables
    // or direct configuration.

    final uri = Uri.parse(url);
    final client = io.HttpClient();

    try {
      // Configure proxy if available
      final proxyUrl = uri.scheme == 'https'
          ? proxyConfig?.getHttpsProxyUrl()
          : proxyConfig?.getHttpProxyUrl();

      if (proxyUrl != null) {
        final proxyUri = Uri.parse(proxyUrl);
        client.findProxy = (uri) {
          return 'PROXY ${proxyUri.host}:${proxyUri.port}';
        };

        // Handle proxy authentication
        if (proxyUri.userInfo.isNotEmpty) {
          client.addProxyCredentials(
            proxyUri.host,
            proxyUri.port,
            '',
            io.HttpClientBasicCredentials(
              proxyUri.userInfo.split(':')[0],
              proxyUri.userInfo.split(':').length > 1
                  ? proxyUri.userInfo.split(':')[1]
                  : '',
            ),
          );
        }
      }

      // Set timeout
      client.connectionTimeout = timeout;

      // Make request based on method
      final io.HttpClientRequest request;
      if (method == 'POST') {
        request = await client.postUrl(uri).timeout(timeout);
      } else {
        request = await client.getUrl(uri).timeout(timeout);
      }

      // Add headers
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Add body for POST requests
      if (body != null && method == 'POST') {
        request.write(body);
      }

      // Get response
      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      // Convert HttpHeaders to Map<String, String>
      final headersMap = <String, String>{};
      response.headers.forEach((name, values) {
        headersMap[name] = values.join(', ');
      });

      return http.Response(
        responseBody,
        response.statusCode,
        headers: headersMap,
      );
    } finally {
      client.close();
    }
  }

  /// Closes the HTTP client and releases resources.
  void close() {
    _customClient?.close();
  }

  /// Executes a request with automatic retry on HTTP 429 (rate limiting).
  ///
  /// When a proxy is configured with [ProxyConfig.retriesWhenBlocked] > 0,
  /// requests returning HTTP 429 are automatically retried with exponential
  /// backoff. Each retry rotates the proxy IP (for rotating proxies like
  /// Webshare), so the next attempt may succeed.
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() execute,
  ) async {
    final maxRetries = proxyConfig?.retriesWhenBlocked ?? 0;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final response = await execute();

      if (response.statusCode == 429 && attempt < maxRetries) {
        // Exponential backoff: 1s, 2s, 4s, 8s, ...
        final delayMs = (1 << attempt) * 1000;
        await Future.delayed(Duration(milliseconds: delayMs));
        continue;
      }

      return response;
    }

    // Should not be reachable — last iteration always returns
    throw io.HttpException('Request failed: max retries exceeded');
  }

  /// Sets a cookie for the given domain.
  ///
  /// Used for consent cookie handling and other cookie-based features.
  void setCookie(String name, String value, {String domain = '.youtube.com'}) {
    _cookies['$name@$domain'] = value;
  }

  /// Sets cookies from a Set-Cookie header value.
  void _storeCookiesFromResponse(String? setCookieHeader) {
    if (setCookieHeader == null) return;
    for (final cookie in setCookieHeader.split(',')) {
      final parts = cookie.trim().split(';');
      if (parts.isEmpty) continue;
      final nameValue = parts[0].split('=');
      if (nameValue.length >= 2) {
        final name = nameValue[0].trim();
        final value = nameValue.sublist(1).join('=').trim();
        _cookies[name] = value;
      }
    }
  }

  /// Builds a Cookie header from stored cookies.
  String? _buildCookieHeader(String url) {
    if (_cookies.isEmpty) return null;
    final uri = Uri.parse(url);
    final domain = uri.host;
    final cookies = <String>[];
    for (final entry in _cookies.entries) {
      // Check if cookie domain matches
      if (entry.key.endsWith('@$domain') ||
          entry.key.endsWith('@.youtube.com') &&
              domain.endsWith('youtube.com')) {
        final name = entry.key.split('@').first;
        cookies.add('$name=${entry.value}');
      }
      // Also include simple-name cookies (no domain)
      if (!entry.key.contains('@')) {
        cookies.add('${entry.key}=${entry.value}');
      }
    }
    return cookies.isEmpty ? null : cookies.join('; ');
  }
}
