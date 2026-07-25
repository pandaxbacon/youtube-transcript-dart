/// Base exception for all transcript-related errors.
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

  RequestBlockedException(String videoId, {this.statusCode})
      : super(
          'The request was blocked by YouTube. This might be due to bot detection. Consider using a proxy',
          videoId: videoId,
        );

  @override
  String toString() {
    if (statusCode != null) {
      return 'RequestBlockedException: $message (HTTP $statusCode) (videoId: $videoId)';
    }
    return super.toString();
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
      : super('Invalid video ID format', videoId: videoId);
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
