/// Base class for proxy configuration.
abstract class ProxyConfig {
  /// Returns the proxy URL to use for HTTP requests.
  String? getHttpProxyUrl();

  /// Returns the proxy URL to use for HTTPS requests.
  String? getHttpsProxyUrl();

  /// Returns custom headers to include in requests when using this proxy.
  Map<String, String> getHeaders() => {};
}

/// Configuration for using Webshare rotating residential proxies.
///
/// Webshare provides rotating residential proxies that can help avoid
/// YouTube's rate limiting and IP blocking.
class WebshareProxyConfig extends ProxyConfig {
  /// Your Webshare proxy username.
  final String username;

  /// Your Webshare proxy password.
  final String password;

  /// Optional location filter (e.g., 'US', 'DE').
  final String? location;

  /// The Webshare proxy host (defaults to p.webshare.io).
  final String host;

  /// The Webshare proxy port (defaults to 80).
  final int port;

  WebshareProxyConfig({
    required this.username,
    required this.password,
    this.location,
    this.host = 'p.webshare.io',
    this.port = 80,
  });

  String _buildProxyUrl() {
    final auth = '$username:$password';
    final locationSuffix = location != null ? '-country-$location' : '';
    return 'http://$auth@$host$locationSuffix:$port';
  }

  @override
  String? getHttpProxyUrl() => _buildProxyUrl();

  @override
  String? getHttpsProxyUrl() => _buildProxyUrl();

  @override
  String toString() {
    return 'WebshareProxyConfig(username: $username, host: $host, port: $port, location: $location)';
  }
}

/// Generic proxy configuration for HTTP and HTTPS proxies.
class GenericProxyConfig extends ProxyConfig {
  /// HTTP proxy URL (e.g., 'http://proxy.example.com:8080').
  final String? httpUrl;

  /// HTTPS proxy URL (e.g., 'https://proxy.example.com:8443').
  final String? httpsUrl;

  /// Optional custom headers to include in requests.
  final Map<String, String>? customHeaders;

  GenericProxyConfig({this.httpUrl, this.httpsUrl, this.customHeaders}) {
    if (httpUrl == null && httpsUrl == null) {
      throw ArgumentError(
        'At least one of httpUrl or httpsUrl must be provided',
      );
    }
  }

  @override
  String? getHttpProxyUrl() => httpUrl;

  @override
  String? getHttpsProxyUrl() => httpsUrl;

  @override
  Map<String, String> getHeaders() => customHeaders ?? {};

  @override
  String toString() {
    return 'GenericProxyConfig(httpUrl: $httpUrl, httpsUrl: $httpsUrl)';
  }
}
