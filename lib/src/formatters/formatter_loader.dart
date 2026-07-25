import 'dart:convert';
import '../models/fetched_transcript.dart';
import 'base_formatter.dart';
import 'csv_formatter.dart';
import 'json_formatter.dart';
import 'srt_formatter.dart';
import 'text_formatter.dart';
import 'vtt_formatter.dart';

/// Formats a transcript as a pretty-printed string representation.
///
/// This formatter produces a human-readable dump of the transcript data
/// using JSON pretty-printing, suitable for debugging or inspection.
class PrettyPrintFormatter extends TranscriptFormatter {
  /// Whether to indent the output (defaults to true for readability).
  final bool pretty;

  PrettyPrintFormatter({this.pretty = true});

  @override
  String format(FetchedTranscript transcript) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(transcript.toRawData());
  }

  /// Formats multiple transcripts as a pretty-printed JSON array.
  String formatAll(List<FetchedTranscript> transcripts) {
    final allData = transcripts.map((t) => t.toRawData()).toList();
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(allData);
  }

  @override
  String get fileExtension => 'json';

  @override
  String get mimeType => 'application/json';

  @override
  String toString() => 'PrettyPrintFormatter(pretty: $pretty)';
}

/// Registry that loads formatters by type name.
///
/// Matches the Python `FormatterLoader` pattern, allowing CLI and
/// programmatic users to select formatters by string name.
class FormatterLoader {
  /// Map of format type names to their default instances.
  static final Map<String, TranscriptFormatter Function()> _types = {
    'json': () => JsonFormatter(pretty: true),
    'pretty': () => PrettyPrintFormatter(),
    'text': () => TextFormatter(),
    'text-ts': () => TextFormatterWithTimestamps(),
    'webvtt': () => VttFormatter(),
    'srt': () => SrtFormatter(),
    'csv': () => CsvFormatter(),
  };

  /// Returns the list of supported formatter type names.
  static List<String> get supportedTypes => _types.keys.toList();

  /// Loads a formatter by type name.
  ///
  /// Throws [ArgumentError] if the type is not supported.
  static TranscriptFormatter load(String type) {
    final factory = _types[type];
    if (factory == null) {
      throw ArgumentError(
        "The format '$type' is not supported. "
        'Choose one of: ${supportedTypes.join(", ")}',
      );
    }
    return factory();
  }
}

/// Extension on [TranscriptFormatter] to support formatting multiple
/// transcripts at once.
extension TranscriptFormatterExtension on TranscriptFormatter {
  /// Formats a list of transcripts into a single string.
  ///
  /// For text-based formatters, transcripts are joined with newlines.
  /// Override in subclasses for format-specific behavior.
  String formatAll(List<FetchedTranscript> transcripts) {
    return transcripts.map(format).join('\n');
  }
}
