import 'dart:convert';
import 'exceptions.dart';
import 'http/http_client.dart';
import 'http/proxy_config.dart';
import 'models/fetched_transcript.dart';
import 'models/transcript.dart';
import 'models/transcript_list.dart';
import 'parsing/transcript_parser.dart';
import 'parsing/transcript_list_parser.dart';
import 'settings.dart';

/// Main API class for fetching YouTube transcripts.
///
/// Example usage:
/// ```dart
/// final api = YouTubeTranscriptApi();
///
/// // Fetch a transcript
/// final transcript = await api.fetch('VIDEO_ID', languages: ['en']);
/// for (var snippet in transcript) {
///   print('${snippet.start}: ${snippet.text}');
/// }
///
/// // List available transcripts
/// final list = await api.list('VIDEO_ID');
/// for (var transcript in list) {
///   print('${transcript.language} (${transcript.languageCode})');
/// }
/// ```
class YouTubeTranscriptApi {
  final TranscriptHttpClient _httpClient;
  final bool _closeClientOnDispose;

  /// Creates a new YouTube Transcript API client.
  ///
  /// [proxyConfig] - Optional proxy configuration for routing requests.
  /// [headers] - Optional custom headers to include in requests.
  /// [timeout] - Request timeout duration (default: 30 seconds).
  /// [httpClient] - Optional custom HTTP client (primarily for testing).
  YouTubeTranscriptApi({
    ProxyConfig? proxyConfig,
    Map<String, String>? headers,
    Duration? timeout,
    TranscriptHttpClient? httpClient,
  })  : _httpClient = httpClient ??
            TranscriptHttpClient(
              proxyConfig: proxyConfig,
              defaultHeaders: headers,
              timeout: timeout ?? const Duration(seconds: 30),
            ),
        _closeClientOnDispose = httpClient == null;

  /// Fetches a transcript for the given video ID.
  ///
  /// [videoId] - The YouTube video ID (e.g., 'dQw4w9WgXcQ').
  /// [languages] - Optional prioritized list of language codes.
  ///               If not provided, defaults to English ['en'].
  /// [preserveFormatting] - If true, preserves HTML formatting in text.
  ///
  /// Returns a [FetchedTranscript] containing the transcript snippets.
  ///
  /// Throws:
  /// - [VideoUnavailableException] if the video is not available.
  /// - [TranscriptsDisabledException] if transcripts are disabled.
  /// - [NoTranscriptFoundException] if no transcript matches the languages.
  /// - [TranscriptFetchException] for other fetch errors.
  Future<FetchedTranscript> fetch(
    String videoId, {
    List<String>? languages,
    bool preserveFormatting = false,
  }) async {
    final effectiveLanguages = languages ?? ['en'];
    final transcriptList = await list(videoId);

    try {
      final transcript = transcriptList.findTranscript(effectiveLanguages);
      return await transcript.fetch(preserveFormatting: preserveFormatting);
    } on NoTranscriptFoundException {
      rethrow;
    } catch (e) {
      throw TranscriptFetchException(
        'Failed to fetch transcript',
        videoId: videoId,
        cause: e,
      );
    }
  }

  /// Lists all available transcripts for a video.
  ///
  /// [videoId] - The YouTube video ID.
  ///
  /// Returns a [TranscriptList] containing all available transcripts.
  ///
  /// Throws:
  /// - [VideoUnavailableException] if the video is not available.
  /// - [TranscriptsDisabledException] if transcripts are disabled.
  /// - [TranscriptFetchException] for other fetch errors.
  Future<TranscriptList> list(String videoId) async {
    _validateVideoId(videoId);

    try {
      // NEW: Use InnerTube API approach (matching Python implementation)

      // Step 1: Fetch the YouTube video page HTML
      final videoUrl = watchUrl.replaceAll('{video_id}', videoId);
      final htmlResponse = await _httpClient.get(videoUrl);
      _checkResponseStatus(htmlResponse.statusCode, videoId);

      // Step 2: Extract the InnerTube API key from the HTML
      final apiKey = _extractInnertubeApiKey(htmlResponse.body, videoId);

      // Step 3: Make POST request to InnerTube API (pretending to be Android)
      final innertubeData = await _fetchInnertubeData(videoId, apiKey);

      // Step 4: Extract captions JSON from InnerTube response
      final captionsJson = _extractCaptionsJson(innertubeData, videoId);

      // Step 5: Parse the transcript list
      return TranscriptListParser.parse(
        videoId: videoId,
        captionsJson: captionsJson,
        fetchFunction: _fetchTranscriptContent,
      );
    } catch (e) {
      if (e is TranscriptException) rethrow;
      throw TranscriptFetchException(
        'Failed to list transcripts',
        videoId: videoId,
        cause: e,
      );
    }
  }

  /// Extracts the InnerTube API key from YouTube's HTML page.
  String _extractInnertubeApiKey(String html, String videoId) {
    final match = innertubeApiKeyPattern.firstMatch(html);

    if (match != null && match.groupCount >= 1) {
      final apiKey = match.group(1);
      if (apiKey != null && apiKey.isNotEmpty) {
        return apiKey;
      }
    }

    // Check for reCAPTCHA (IP blocked)
    if (html.contains('class="g-recaptcha"')) {
      throw IpBlockedException(videoId);
    }

    throw TranscriptFetchException(
      'Could not extract InnerTube API key from YouTube page',
      videoId: videoId,
    );
  }

  /// Fetches data from YouTube's InnerTube API.
  Future<Map<String, dynamic>> _fetchInnertubeData(
    String videoId,
    String apiKey,
  ) async {
    final url = innertubeApiUrl.replaceAll('{api_key}', apiKey);

    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'context': innertubeContext, 'videoId': videoId}),
    );

    _checkResponseStatus(response.statusCode, videoId);

    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw TranscriptParseException(
        'Failed to parse InnerTube API response as JSON',
        videoId: videoId,
        cause: e,
      );
    }
  }

  /// Extracts captions JSON from InnerTube API response.
  Map<String, dynamic> _extractCaptionsJson(
    Map<String, dynamic> innertubeData,
    String videoId,
  ) {
    // Check playability status
    final playabilityStatus = innertubeData['playabilityStatus'];
    if (playabilityStatus is Map<String, dynamic>) {
      _checkPlayabilityStatus(playabilityStatus, videoId);
    }

    // Extract captions
    final captions = innertubeData['captions'];
    if (captions is! Map<String, dynamic>) {
      throw TranscriptsDisabledException(videoId);
    }

    final captionsRenderer = captions['playerCaptionsTracklistRenderer'];
    if (captionsRenderer is! Map<String, dynamic>) {
      throw TranscriptsDisabledException(videoId);
    }

    final captionTracks = captionsRenderer['captionTracks'];
    if (captionTracks == null ||
        captionTracks is! List ||
        captionTracks.isEmpty) {
      throw TranscriptsDisabledException(videoId);
    }

    return captionsRenderer;
  }

  /// Checks playability status and throws appropriate exceptions.
  void _checkPlayabilityStatus(
    Map<String, dynamic> playabilityStatus,
    String videoId,
  ) {
    final status = playabilityStatus['status'] as String?;

    if (status == 'OK') {
      return; // Video is playable
    }

    final reason = playabilityStatus['reason'] as String?;

    // Handle specific error cases
    if (status == 'LOGIN_REQUIRED') {
      if (reason?.contains('not a bot') ?? false) {
        throw RequestBlockedException(videoId);
      }
      if (reason?.contains('inappropriate') ?? false) {
        throw VideoUnavailableException(videoId); // Age restricted
      }
    }

    if (status == 'ERROR' && (reason?.contains('unavailable') ?? false)) {
      if (videoId.startsWith('http://') || videoId.startsWith('https://')) {
        throw InvalidVideoIdException(videoId);
      }
      throw VideoUnavailableException(videoId);
    }

    // Generic error
    throw TranscriptFetchException(
      'Video is not playable: ${reason ?? "Unknown reason"}',
      videoId: videoId,
    );
  }

  /// Convenience method to find a transcript matching language preferences.
  ///
  /// This is equivalent to calling [list] and then calling
  /// [TranscriptList.findTranscript].
  Future<Transcript> findTranscript(
    String videoId,
    List<String> languages,
  ) async {
    final transcriptList = await list(videoId);
    return transcriptList.findTranscript(languages);
  }

  /// Convenience method to find a manually created transcript.
  Future<Transcript> findManuallyCreatedTranscript(
    String videoId,
    List<String> languages,
  ) async {
    final transcriptList = await list(videoId);
    return transcriptList.findManuallyCreatedTranscript(languages);
  }

  /// Convenience method to find an auto-generated transcript.
  Future<Transcript> findGeneratedTranscript(
    String videoId,
    List<String> languages,
  ) async {
    final transcriptList = await list(videoId);
    return transcriptList.findGeneratedTranscript(languages);
  }

  /// Internal method to fetch transcript content from a URL.
  Future<FetchedTranscript> _fetchTranscriptContent(
    String url,
    bool preserveFormatting,
  ) async {
    try {
      final response = await _httpClient.get(url);

      if (!response.isSuccessful) {
        final videoId = _extractVideoIdFromUrl(url);
        _checkResponseStatus(response.statusCode, videoId);
      }

      // Parse the XML response
      final snippets = TranscriptParser.parseXml(
        response.body,
        preserveFormatting: preserveFormatting,
      );

      // Extract metadata from URL
      final uri = Uri.parse(url);
      final videoId = _extractVideoIdFromUrl(url);
      final languageCode = uri.queryParameters['lang'] ?? 'unknown';
      final translationLang = uri.queryParameters['tlang'];
      final isTranslated = translationLang != null;

      return TranscriptParser.createFetchedTranscript(
        videoId: videoId,
        language: languageCode,
        languageCode: languageCode,
        isGenerated: url.contains('kind=asr'),
        isTranslated: isTranslated,
        snippets: snippets,
      );
    } catch (e) {
      if (e is TranscriptException) rethrow;
      throw TranscriptFetchException(
        'Failed to fetch transcript content',
        cause: e,
      );
    }
  }

  /// Validates a video ID format.
  void _validateVideoId(String videoId) {
    if (videoId.isEmpty) {
      throw InvalidVideoIdException(videoId);
    }

    // Basic validation: YouTube video IDs are typically 11 characters
    if (videoId.length != 11 ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(videoId)) {
      throw InvalidVideoIdException(videoId);
    }
  }

  /// Checks HTTP response status and throws appropriate exceptions.
  void _checkResponseStatus(int statusCode, String videoId) {
    if (statusCode == 429) {
      throw TooManyRequestsException(videoId);
    } else if (statusCode == 403) {
      throw IpBlockedException(videoId, statusCode: statusCode);
    } else if (statusCode >= 400 && statusCode < 500) {
      if (statusCode == 404) {
        throw VideoUnavailableException(videoId);
      }
      throw RequestBlockedException(videoId, statusCode: statusCode);
    } else if (statusCode >= 500) {
      throw TranscriptFetchException(
        'YouTube server error (HTTP $statusCode)',
        videoId: videoId,
      );
    }
  }

  /// Extracts video ID from a URL.
  String _extractVideoIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['v'] ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Closes the HTTP client and releases resources.
  void dispose() {
    if (_closeClientOnDispose) {
      _httpClient.close();
    }
  }
}
