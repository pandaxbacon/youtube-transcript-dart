import 'package:html/parser.dart' as html_parser;
import '../exceptions.dart';
import '../models/transcript_snippet.dart';
import '../models/fetched_transcript.dart';

/// Parses transcript data from YouTube's XML response.
class TranscriptParser {
  /// Parses the XML transcript response into a list of snippets.
  static List<TranscriptSnippet> parseXml(
    String xmlContent, {
    bool preserveFormatting = false,
  }) {
    try {
      final document = html_parser.parse(xmlContent);
      final textElements = document.querySelectorAll('text');

      if (textElements.isEmpty) {
        throw TranscriptParseException(
          'No transcript text elements found in response',
        );
      }

      final snippets = <TranscriptSnippet>[];

      for (final element in textElements) {
        final startStr = element.attributes['start'];
        final durationStr =
            element.attributes['dur'] ?? element.attributes['duration'];
        final text = element.text;

        // Skip elements without text or start time (matches Python implementation)
        if (text.isEmpty || startStr == null) {
          continue;
        }

        final start = double.tryParse(startStr);
        final duration =
            durationStr != null ? double.tryParse(durationStr) : 0.0;

        if (start == null) {
          continue;
        }

        // Decode HTML entities first (before stripping formatting)
        var processedText = _decodeHtmlEntities(text);

        // Handle HTML tags and formatting
        if (!preserveFormatting) {
          processedText = _stripFormatting(processedText);
        }

        snippets.add(
          TranscriptSnippet(
            text: processedText,
            start: start,
            duration: duration ?? 0.0,
          ),
        );
      }

      if (snippets.isEmpty) {
        throw TranscriptParseException(
          'No valid transcript snippets could be parsed',
        );
      }

      return snippets;
    } catch (e) {
      if (e is TranscriptParseException) rethrow;
      throw TranscriptParseException(
        'Failed to parse transcript XML',
        cause: e,
      );
    }
  }

  /// Creates a FetchedTranscript from parsed snippets and metadata.
  static FetchedTranscript createFetchedTranscript({
    required String videoId,
    required String language,
    required String languageCode,
    required bool isGenerated,
    required bool isTranslated,
    required List<TranscriptSnippet> snippets,
  }) {
    return FetchedTranscript(
      videoId: videoId,
      language: language,
      languageCode: languageCode,
      isGenerated: isGenerated,
      isTranslated: isTranslated,
      snippets: snippets,
    );
  }

  /// Strips HTML formatting tags from text.
  static String _stripFormatting(String text) {
    // Remove common HTML tags
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Decodes HTML entities in text.
  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        // Decode numeric entities
        .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '');
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    }).replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '', radix: 16);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });
  }
}
