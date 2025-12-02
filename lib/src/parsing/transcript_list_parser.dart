import 'dart:convert';
import '../exceptions.dart';
import '../models/transcript.dart';
import '../models/transcript_list.dart';
import '../models/translation_language.dart';
import '../models/fetched_transcript.dart';

/// Parses transcript list data from YouTube's response.
class TranscriptListParser {
  /// Extracts the captions JSON from the YouTube page HTML.
  static Map<String, dynamic>? extractCaptionsJson(String html) {
    try {
      // Look for the player response in the HTML
      final patterns = [
        RegExp(r'ytInitialPlayerResponse\s*=\s*({.+?})\s*;', dotAll: true),
        RegExp(
          r'"captions":\s*({.+?"playerCaptionsTracklistRenderer".+?})',
          dotAll: true,
        ),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(html);
        if (match != null) {
          try {
            final jsonStr = match.group(1);
            if (jsonStr != null) {
              final data = json.decode(jsonStr) as Map<String, dynamic>;

              // Extract captions data
              if (data.containsKey('captions')) {
                return data['captions'] as Map<String, dynamic>?;
              }

              // If the whole match was a captions object
              if (data.containsKey('playerCaptionsTracklistRenderer')) {
                return data;
              }

              // Look deeper in player response
              final captions = _findCaptionsInObject(data);
              if (captions != null) {
                return captions;
              }
            }
          } catch (e) {
            continue; // Try next pattern
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Recursively searches for captions data in a JSON object.
  static Map<String, dynamic>? _findCaptionsInObject(Map<String, dynamic> obj) {
    if (obj.containsKey('playerCaptionsTracklistRenderer')) {
      return obj;
    }

    if (obj.containsKey('captions')) {
      final captions = obj['captions'];
      if (captions is Map<String, dynamic>) {
        return captions;
      }
    }

    for (final value in obj.values) {
      if (value is Map<String, dynamic>) {
        final result = _findCaptionsInObject(value);
        if (result != null) return result;
      }
    }

    return null;
  }

  /// Parses the transcript list from captions JSON data.
  ///
  /// Note: captionsJson should be the playerCaptionsTracklistRenderer object directly,
  /// not a parent object containing it.
  static TranscriptList parse({
    required String videoId,
    required Map<String, dynamic> captionsJson,
    required Future<FetchedTranscript> Function(
      String url,
      bool preserveFormatting,
    ) fetchFunction,
  }) {
    try {
      // captionsJson IS the playerCaptionsTracklistRenderer
      final renderer = captionsJson;

      final captionTracks = renderer['captionTracks'] as List<dynamic>?;
      if (captionTracks == null || captionTracks.isEmpty) {
        throw TranscriptsDisabledException(videoId);
      }

      final transcripts = <Transcript>[];

      for (final track in captionTracks) {
        if (track is! Map<String, dynamic>) continue;

        final baseUrl = track['baseUrl'] as String?;
        final languageCode = track['languageCode'] as String?;
        final kind = track['kind'] as String?;
        final isGenerated = kind == 'asr';
        final isTranslatable = track['isTranslatable'] as bool? ?? false;

        if (baseUrl == null || languageCode == null) continue;

        // Extract language name from runs array (InnerTube format)
        final name = track['name'] as Map<String, dynamic>?;
        String languageName = languageCode;
        if (name != null) {
          final runs = name['runs'] as List<dynamic>?;
          if (runs != null && runs.isNotEmpty) {
            final firstRun = runs[0] as Map<String, dynamic>?;
            languageName = firstRun?['text'] as String? ?? languageCode;
          }
        }

        // Parse translation languages (only if translatable)
        final translationLanguages = <TranslationLanguage>[];
        if (isTranslatable) {
          final translations =
              renderer['translationLanguages'] as List<dynamic>?;

          if (translations != null) {
            for (final translation in translations) {
              if (translation is! Map<String, dynamic>) continue;

              final transLangCode = translation['languageCode'] as String?;
              final transLangName =
                  translation['languageName'] as Map<String, dynamic>?;

              if (transLangCode != null && transLangName != null) {
                // Extract from runs array (InnerTube format)
                final transRuns = transLangName['runs'] as List<dynamic>?;
                if (transRuns != null && transRuns.isNotEmpty) {
                  final transFirstRun = transRuns[0] as Map<String, dynamic>?;
                  final transName =
                      transFirstRun?['text'] as String? ?? transLangCode;

                  translationLanguages.add(
                    TranslationLanguage(
                      languageCode: transLangCode,
                      languageName: transName,
                    ),
                  );
                }
              }
            }
          }
        }

        // Remove &fmt=srv3 from the URL (matches Python implementation)
        final cleanedUrl = baseUrl.replaceAll('&fmt=srv3', '');

        transcripts.add(
          Transcript(
            videoId: videoId,
            language: languageName,
            languageCode: languageCode,
            isGenerated: isGenerated,
            isTranslatable: translationLanguages.isNotEmpty,
            translationLanguages: translationLanguages,
            transcriptUrl: cleanedUrl,
            fetchFunction: fetchFunction,
          ),
        );
      }

      if (transcripts.isEmpty) {
        throw TranscriptsDisabledException(videoId);
      }

      return TranscriptList(videoId: videoId, transcripts: transcripts);
    } catch (e) {
      if (e is TranscriptException) rethrow;
      throw TranscriptParseException(
        'Failed to parse transcript list',
        videoId: videoId,
        cause: e,
      );
    }
  }
}
