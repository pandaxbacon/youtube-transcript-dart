/// Base class for proxy configuration.
abstract class ProxyConfig {
  /// Returns the proxy URL to use for HTTP requests.
  String? getHttpProxyUrl();

  /// Returns the proxy URL to use for HTTPS requests.
  String? getHttpsProxyUrl();

  /// Returns custom headers to include in requests when using this proxy.
  Map<String, String> getHeaders() => {};

  /// How many times to retry when a request is blocked (HTTP 429).
  ///
  /// When using rotating proxies, a retry triggers an IP rotation so the
  /// next attempt may use a different, unblocked IP.
  int get retriesWhenBlocked => 0;

  /// Whether to prevent the HTTP client from keeping TCP connections alive.
  ///
  /// When using rotating proxies, keeping connections alive can prevent
  /// IP rotation between requests. Setting this to true adds a
  /// `Connection: close` header so each request gets a fresh connection
  /// and potentially a new proxy IP.
  bool get preventKeepingConnectionsAlive => false;
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
  /// You can also pass a list to filter by multiple locations.
  final List<String>? locations;

  /// The Webshare proxy host (defaults to p.webshare.io).
  final String host;

  /// The Webshare proxy port (defaults to 80).
  final int port;

  /// How many times to retry when a request is blocked (HTTP 429).
  ///
  /// Defaults to 10, which is appropriate for Webshare's rotating residential
  /// proxies — each retry triggers an IP rotation so the next attempt uses a
  /// different IP.
  final int retries;

  WebshareProxyConfig({
    required this.username,
    required this.password,
    this.locations,
    this.host = 'p.webshare.io',
    this.port = 80,
    this.retries = 10,
  });

  /// Convenience constructor that accepts a single location string.
  factory WebshareProxyConfig.withLocation({
    required String username,
    required String password,
    String? location,
    String host = 'p.webshare.io',
    int port = 80,
    int retries = 10,
  }) {
    return WebshareProxyConfig(
      username: username,
      password: password,
      locations: location != null ? [location] : null,
      host: host,
      port: port,
      retries: retries,
    );
  }

  @override
  int get retriesWhenBlocked => retries;

  @override
  bool get preventKeepingConnectionsAlive => true;

  String _buildProxyUrl() {
    // Build username with optional location filter and -rotate suffix.
    // Format: username-country-XX-rotate:password@p.webshare.io:port
    //
    // The -rotate suffix tells Webshare to cycle IPs on each connection.
    // Country filter (e.g. -country-US) narrows the IP pool to a region.
    var effectiveUsername = username;

    // Remove existing -rotate suffix if present (prevents duplication)
    const rotateSuffix = '-rotate';
    if (effectiveUsername.endsWith(rotateSuffix)) {
      effectiveUsername = effectiveUsername.substring(
        0,
        effectiveUsername.length - rotateSuffix.length,
      );
    }

    // Build location filter segment
    final locationSegments = <String>[];
    if (locations != null) {
      for (final loc in locations!) {
        locationSegments.add('-country-${loc.toUpperCase()}');
      }
    }
    final locationFilter = locationSegments.join();

    final proxyAuth =
        '$effectiveUsername$locationFilter$rotateSuffix:$password';
    return 'http://$proxyAuth@$host:$port';
  }

  @override
  String? getHttpProxyUrl() => _buildProxyUrl();

  @override
  String? getHttpsProxyUrl() => _buildProxyUrl();

  @override
  String toString() {
    return 'WebshareProxyConfig(username: $username, host: $host, port: $port, locations: $locations)';
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
