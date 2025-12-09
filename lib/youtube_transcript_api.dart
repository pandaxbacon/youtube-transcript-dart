/// A Dart library to fetch YouTube transcripts and subtitles.
///
/// This library allows you to retrieve transcripts for YouTube videos,
/// including both manually created and auto-generated subtitles.
/// It does not require an API key.
///
/// Example usage:
/// ```dart
/// import 'package:youtube_transcript_api/youtube_transcript_api.dart';
///
/// void main() async {
///   final api = YouTubeTranscriptApi();
///
///   // Fetch a transcript
///   final transcript = await api.fetch('dQw4w9WgXcQ');
///   for (var snippet in transcript) {
///     print('${snippet.start}: ${snippet.text}');
///   }
///
///   // List available transcripts
///   final transcriptList = await api.list('dQw4w9WgXcQ');
///   for (var t in transcriptList) {
///     print('${t.language} (${t.languageCode}) - Generated: ${t.isGenerated}');
///   }
/// }
/// ```
library;

// Core API
export 'src/youtube_transcript_api_base.dart';

// Models
export 'src/models/fetched_transcript.dart';
export 'src/models/transcript.dart';
export 'src/models/transcript_list.dart';
export 'src/models/transcript_snippet.dart';
export 'src/models/translation_language.dart';
export 'src/models/batch_transcript_result.dart';

// Exceptions
export 'src/exceptions.dart'
    show
        TranscriptException,
        VideoUnavailableException,
        TranscriptsDisabledException,
        NoTranscriptFoundException,
        NoTranscriptManuallyCreatedException,
        NoTranscriptGeneratedException,
        TranslationNotAvailableException,
        TooManyRequestsException,
        RequestBlockedException,
        IpBlockedException,
        InvalidVideoIdException,
        TranscriptFetchException,
        TranscriptParseException,
        InvalidCookiesException,
        PoTokenRequiredException;

// HTTP & Proxy
export 'src/http/http_client.dart';
export 'src/http/proxy_config.dart';

// Formatters
export 'src/formatters/base_formatter.dart';
export 'src/formatters/text_formatter.dart';
export 'src/formatters/json_formatter.dart';
export 'src/formatters/vtt_formatter.dart';
export 'src/formatters/srt_formatter.dart';
export 'src/formatters/csv_formatter.dart';
