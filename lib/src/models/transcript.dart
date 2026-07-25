import '../exceptions.dart';
import 'fetched_transcript.dart';
import 'translation_language.dart';

/// Represents metadata about a transcript that can be fetched.
///
/// Use the [fetch] method to retrieve the actual transcript content.
class Transcript {
  /// The YouTube video ID.
  final String videoId;

  /// The language name (e.g., 'English', 'German').
  final String language;

  /// The language code (e.g., 'en', 'de').
  final String languageCode;

  /// Whether this is an auto-generated transcript.
  final bool isGenerated;

  /// Whether this transcript can be translated.
  final bool isTranslatable;

  /// Available translation languages.
  final List<TranslationLanguage> translationLanguages;

  /// Internal: The URL to fetch the transcript from.
  final String? transcriptUrl;

  /// Internal: Translation language code if this is a translated transcript.
  final String? translationLanguageCode;

  /// Internal: Function to fetch the transcript content.
  final Future<FetchedTranscript> Function(String url, bool preserveFormatting)?
      _fetchFunction;

  Transcript({
    required this.videoId,
    required this.language,
    required this.languageCode,
    required this.isGenerated,
    required this.isTranslatable,
    required this.translationLanguages,
    this.transcriptUrl,
    this.translationLanguageCode,
    Future<FetchedTranscript> Function(String url, bool preserveFormatting)?
        fetchFunction,
  }) : _fetchFunction = fetchFunction;

  /// Fetches the actual transcript content.
  ///
  /// [preserveFormatting] - If true, HTML formatting tags in the transcript
  /// text will be preserved. If false (default), they will be removed.
  ///
  /// Throws [TranscriptFetchException] if the fetch fails.
  /// Throws [PoTokenRequiredException] if YouTube requires proof-of-origin token.
  Future<FetchedTranscript> fetch({bool preserveFormatting = false}) async {
    if (_fetchFunction == null || transcriptUrl == null) {
      throw TranscriptFetchException(
        'Cannot fetch transcript: missing fetch function or URL',
        videoId: videoId,
      );
    }

    // Check for PoToken requirement (YouTube's anti-bot protection)
    if (transcriptUrl!.contains('&exp=xpe')) {
      throw PoTokenRequiredException(videoId);
    }

    return await _fetchFunction!(transcriptUrl!, preserveFormatting);
  }

  /// Returns a new [Transcript] configured to fetch the translated version.
  ///
  /// [targetLanguageCode] - The language code to translate to (e.g., 'en', 'de').
  ///
  /// Throws [TranslationNotAvailableException] if translation is not available
  /// for the target language.
  Transcript translate(String targetLanguageCode) {
    if (!isTranslatable) {
      throw TranslationNotAvailableException(
        videoId: videoId,
        targetLanguage: targetLanguageCode,
      );
    }

    final targetLanguage = translationLanguages.firstWhere(
      (lang) => lang.languageCode == targetLanguageCode,
      orElse: () => throw TranslationNotAvailableException(
        videoId: videoId,
        targetLanguage: targetLanguageCode,
      ),
    );

    // Construct the translated transcript URL
    var translatedUrl = transcriptUrl;
    if (translatedUrl != null && translatedUrl.contains('&tlang=')) {
      // Replace existing translation parameter
      translatedUrl = translatedUrl.replaceFirst(
        RegExp(r'&tlang=[^&]*'),
        '&tlang=$targetLanguageCode',
      );
    } else if (translatedUrl != null) {
      // Add translation parameter
      translatedUrl = '$translatedUrl&tlang=$targetLanguageCode';
    }

    return Transcript(
      videoId: videoId,
      language: targetLanguage.languageName,
      languageCode: languageCode,
      isGenerated: isGenerated,
      isTranslatable:
          false, // Translated transcripts cannot be translated again
      translationLanguages: [],
      transcriptUrl: translatedUrl,
      translationLanguageCode: targetLanguageCode,
      fetchFunction: _fetchFunction,
    );
  }

  @override
  String toString() {
    return 'Transcript(videoId: $videoId, language: $language, '
        'languageCode: $languageCode, isGenerated: $isGenerated, '
        'isTranslatable: $isTranslatable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transcript &&
        other.videoId == videoId &&
        other.languageCode == languageCode &&
        other.translationLanguageCode == translationLanguageCode;
  }

  @override
  int get hashCode =>
      Object.hash(videoId, languageCode, translationLanguageCode);
}
