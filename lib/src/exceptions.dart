/// Base exception for all transcript-related errors.
library;

import 'http/proxy_config.dart';

class TranscriptException implements Exception {
  final String message;
  final String? videoId;

  TranscriptException(this.message, {this.videoId});

  @override
  String toString() {
    if (videoId != null) {
      return 'TranscriptException: $message (videoId: $videoId)';
    }
    return 'TranscriptException: $message';
  }
}

/// Thrown when the YouTube video is unavailable.
class VideoUnavailableException extends TranscriptException {
  VideoUnavailableException(String videoId)
      : super('The video is not available', videoId: videoId);
}

/// Thrown when transcripts are disabled for the video.
class TranscriptsDisabledException extends TranscriptException {
  TranscriptsDisabledException(String videoId)
      : super('Subtitles are disabled for this video', videoId: videoId);
}

/// Thrown when no transcript is found for the requested languages.
class NoTranscriptFoundException extends TranscriptException {
  final List<String> requestedLanguages;
  final List<String> availableLanguages;

  NoTranscriptFoundException({
    required String videoId,
    required this.requestedLanguages,
    required this.availableLanguages,
  }) : super(
          'No transcript found for languages: ${requestedLanguages.join(", ")}. '
          'Available languages: ${availableLanguages.join(", ")}',
          videoId: videoId,
        );
}

/// Thrown when no manually created transcript is found.
class NoTranscriptManuallyCreatedException extends NoTranscriptFoundException {
  NoTranscriptManuallyCreatedException({
    required super.videoId,
    required super.requestedLanguages,
    required super.availableLanguages,
  });

  @override
  String toString() {
    return 'NoTranscriptManuallyCreatedException: No manually created transcript found for languages: ${requestedLanguages.join(", ")}. '
        'Available languages: ${availableLanguages.join(", ")} (videoId: $videoId)';
  }
}

/// Thrown when no auto-generated transcript is found.
class NoTranscriptGeneratedException extends NoTranscriptFoundException {
  NoTranscriptGeneratedException({
    required super.videoId,
    required super.requestedLanguages,
    required super.availableLanguages,
  });

  @override
  String toString() {
    return 'NoTranscriptGeneratedException: No auto-generated transcript found for languages: ${requestedLanguages.join(", ")}. '
        'Available languages: ${availableLanguages.join(", ")} (videoId: $videoId)';
  }
}

/// Thrown when translation is not available for a transcript.
class TranslationNotAvailableException extends TranscriptException {
  final String targetLanguage;

  TranslationNotAvailableException({
    required String videoId,
    required this.targetLanguage,
  }) : super(
          'Translation to "$targetLanguage" is not available for this transcript',
          videoId: videoId,
        );
}

/// Thrown when too many requests are made to YouTube.
class TooManyRequestsException extends TranscriptException {
  TooManyRequestsException(String videoId)
      : super(
          'YouTube is receiving too many requests from this IP. Please try again later or use a proxy',
          videoId: videoId,
        );
}

/// Thrown when the request is blocked by YouTube (e.g., bot detection).
class RequestBlockedException extends TranscriptException {
  final int? statusCode;
  ProxyConfig? _proxyConfig;

  RequestBlockedException(String videoId, {this.statusCode})
      : _proxyConfig = null,
        super(
          'The request was blocked by YouTube. This might be due to bot detection. Consider using a proxy',
          videoId: videoId,
        );

  @override
  String toString() {
    final buffer = StringBuffer();
    if (statusCode != null) {
      buffer.write(
        'RequestBlockedException: $message (HTTP $statusCode) (videoId: $videoId)',
      );
    } else {
      buffer.write(super.toString());
    }

    // Add proxy-specific guidance
    if (_proxyConfig is WebshareProxyConfig) {
      buffer.write(
        '\n\nYouTube is blocking your requests, despite using Webshare proxies. '
        'Please make sure you have purchased "Residential" proxies and NOT '
        '"Proxy Server" or "Static Residential", as those won\'t work as reliably. '
        'The only reliable option is using "Residential" proxies (not "Static Residential"), '
        'as this allows you to rotate through a pool of over 30M IPs.',
      );
    } else if (_proxyConfig is GenericProxyConfig) {
      buffer.write(
        '\n\nYouTube is blocking your requests, despite using a proxy. '
        'Keep in mind that a proxy is just a way to hide your real IP, '
        'but there is no guarantee that the proxy IP won\'t be blocked as well. '
        'The most reliable way to prevent IP blocks is rotating through a large '
        'pool of residential IPs, by using a provider like Webshare.',
      );
    }

    return buffer.toString();
  }

  /// Attaches proxy configuration context to produce tailored error messages.
  ///
  /// When a proxy is in use, the error message includes specific guidance
  /// based on the proxy type (Webshare, generic, or none).
  RequestBlockedException withProxyConfig(ProxyConfig? proxyConfig) {
    final copy = RequestBlockedException(
      videoId ?? 'unknown',
      statusCode: statusCode,
    );
    copy._proxyConfig = proxyConfig;
    return copy;
  }
}

/// Thrown when the IP address is blocked by YouTube.
class IpBlockedException extends RequestBlockedException {
  IpBlockedException(super.videoId, {super.statusCode});

  @override
  String toString() {
    return 'IpBlockedException: Your IP address has been blocked by YouTube. Please use a proxy (videoId: $videoId)';
  }
}

/// Thrown when the video ID is invalid.
class InvalidVideoIdException extends TranscriptException {
  InvalidVideoIdException(String videoId)
      : super(
          'You provided an invalid video ID. Make sure you are using the '
          'video ID and NOT the URL!\n\n'
          'Do NOT run: api.fetch("https://www.youtube.com/watch?v=1234")\n'
          'Instead run: api.fetch("1234")',
          videoId: videoId,
        );
}

/// Thrown when there's an error fetching the transcript from YouTube.
class TranscriptFetchException extends TranscriptException {
  final Object? cause;

  TranscriptFetchException(super.message, {super.videoId, this.cause});

  @override
  String toString() {
    if (cause != null) {
      return '${super.toString()} - Caused by: $cause';
    }
    return super.toString();
  }
}

/// Thrown when the transcript response cannot be parsed.
class TranscriptParseException extends TranscriptException {
  final Object? cause;

  TranscriptParseException(super.message, {super.videoId, this.cause});

  @override
  String toString() {
    if (cause != null) {
      return '${super.toString()} - Caused by: $cause';
    }
    return super.toString();
  }
}

/// Thrown when cookies are invalid or rejected.
class InvalidCookiesException extends TranscriptException {
  InvalidCookiesException(String videoId)
      : super(
          'The provided cookies are invalid or have been rejected by YouTube',
          videoId: videoId,
        );
}

/// Thrown when a PoToken (Proof of Origin token) is required.
///
/// This is a recent YouTube anti-bot protection measure. Some videos require
/// additional authentication tokens to access transcripts.
class PoTokenRequiredException extends TranscriptException {
  PoTokenRequiredException(String videoId)
      : super(
          'YouTube requires a PoToken (Proof of Origin token) to access this transcript. '
          'This is a recent anti-bot protection measure. '
          'Consider using the Python library which may have updated workarounds, '
          'or try accessing the transcript directly on YouTube.',
          videoId: videoId,
        );
}

/// Thrown when the YouTube video is unplayable for a specific reason.
///
/// Unlike [VideoUnavailableException] which is thrown when the video simply
/// doesn't exist, this exception provides context about _why_ the video
/// cannot be played (e.g., region restrictions, content warnings, etc.).
class VideoUnplayableException extends TranscriptException {
  /// The main reason the video is unplayable (from YouTube's playability status).
  final String? reason;

  /// Additional sub-reasons (from YouTube's error screen).
  final List<String> subReasons;

  VideoUnplayableException({
    required String videoId,
    this.reason,
    this.subReasons = const [],
  }) : super(
          _buildMessage(videoId, reason, subReasons),
          videoId: videoId,
        );

  static String _buildMessage(
    String videoId,
    String? reason,
    List<String> subReasons,
  ) {
    final buffer = StringBuffer('The video is unplayable');
    if (reason != null) {
      buffer.write(': $reason');
    }
    if (subReasons.isNotEmpty) {
      buffer.write('\nAdditional details:');
      for (final sub in subReasons) {
        buffer.write('\n  - $sub');
      }
    }
    return buffer.toString();
  }
}

/// Thrown when the YouTube video is age-restricted and requires authentication.
///
/// Age-restricted videos cannot be accessed without logging in. YouTube has
/// made cookie-based authentication challenging for automated tools, so this
/// exception indicates that the video is age-gated and currently inaccessible.
class AgeRestrictedException extends TranscriptException {
  AgeRestrictedException(String videoId)
      : super(
          'This video is age-restricted. Authentication is required to access '
          'age-restricted videos. Cookie-based authentication is not currently '
          'supported.',
          videoId: videoId,
        );
}

/// Thrown when YouTube's EU consent cookie cannot be created.
///
/// YouTube requires consent for cookie usage in EU regions. The library
/// automatically handles this by setting a CONSENT cookie, but if the
/// required form data cannot be found, this exception is thrown.
class FailedToCreateConsentCookieException extends TranscriptException {
  FailedToCreateConsentCookieException(String videoId)
      : super(
          'Failed to automatically give consent to saving cookies. '
          'YouTube is requiring a consent cookie which could not be created automatically.',
          videoId: videoId,
        );
}

/// Thrown when an HTTP request to YouTube fails.
///
/// Wraps the original HTTP error details (status code, response body)
/// for debugging. Unlike simpler exceptions, this preserves the full
/// HTTP error context.
class YouTubeRequestFailedException extends TranscriptException {
  /// The HTTP status code that caused the failure.
  final int statusCode;

  /// The response body, if available.
  final String? responseBody;

  YouTubeRequestFailedException({
    required String videoId,
    required this.statusCode,
    this.responseBody,
  }) : super(
          'Request to YouTube failed (HTTP $statusCode)',
          videoId: videoId,
        );

  @override
  String toString() {
    final buffer = StringBuffer('YouTubeRequestFailedException: $message');
    if (responseBody != null) {
      buffer.write('\nResponse: $responseBody');
    }
    return buffer.toString();
  }
}
