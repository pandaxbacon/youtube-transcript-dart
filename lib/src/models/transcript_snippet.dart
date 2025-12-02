/// Represents a single snippet/segment of a transcript.
///
/// Each snippet contains the text content along with timing information.
class TranscriptSnippet {
  /// The text content of this snippet.
  final String text;

  /// The start time of this snippet in seconds.
  final double start;

  /// The duration of this snippet in seconds.
  final double duration;

  const TranscriptSnippet({
    required this.text,
    required this.start,
    required this.duration,
  });

  /// Creates a [TranscriptSnippet] from a JSON map.
  factory TranscriptSnippet.fromJson(Map<String, dynamic> json) {
    return TranscriptSnippet(
      text: json['text'] as String,
      start: (json['start'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
    );
  }

  /// Converts this snippet to a JSON map.
  Map<String, dynamic> toJson() {
    return {'text': text, 'start': start, 'duration': duration};
  }

  @override
  String toString() {
    return 'TranscriptSnippet(text: "$text", start: $start, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranscriptSnippet &&
        other.text == text &&
        other.start == start &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(text, start, duration);
}
