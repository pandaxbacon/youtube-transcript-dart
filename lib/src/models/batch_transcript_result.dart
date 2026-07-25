import '../exceptions.dart';
import 'fetched_transcript.dart';

/// Result of a batch transcript fetch operation.
class BatchTranscriptResult {
  /// The video ID this result is for.
  final String videoId;

  /// The fetched transcript (null if failed).
  final FetchedTranscript? transcript;

  /// The error that occurred (null if successful).
  final TranscriptException? error;

  /// Whether the fetch was successful.
  bool get isSuccess => transcript != null;

  /// Whether the fetch failed.
  bool get isFailure => error != null;

  const BatchTranscriptResult({
    required this.videoId,
    this.transcript,
    this.error,
  }) : assert(
          (transcript != null) != (error != null),
          'Either transcript or error must be provided, but not both',
        );

  /// Creates a successful result.
  factory BatchTranscriptResult.success(
    String videoId,
    FetchedTranscript transcript,
  ) {
    return BatchTranscriptResult(videoId: videoId, transcript: transcript);
  }

  /// Creates a failed result.
  factory BatchTranscriptResult.failure(
    String videoId,
    TranscriptException error,
  ) {
    return BatchTranscriptResult(videoId: videoId, error: error);
  }
}
