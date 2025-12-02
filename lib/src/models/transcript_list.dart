import 'dart:collection';
import '../exceptions.dart';
import 'transcript.dart';

/// A collection of available transcripts for a video.
///
/// Provides methods to find transcripts based on language preferences
/// and whether they are manually created or auto-generated.
class TranscriptList extends IterableBase<Transcript> {
  /// The YouTube video ID.
  final String videoId;

  /// The list of available transcripts.
  final List<Transcript> transcripts;

  TranscriptList({required this.videoId, required this.transcripts});

  @override
  Iterator<Transcript> get iterator => transcripts.iterator;

  /// Finds a transcript matching the language preferences.
  ///
  /// [languages] - A prioritized list of language codes (e.g., ['de', 'en']).
  /// The first matching language will be returned.
  ///
  /// Manually created transcripts are preferred over auto-generated ones.
  ///
  /// Throws [NoTranscriptFoundException] if no matching transcript is found.
  Transcript findTranscript(List<String> languages) {
    // First try to find manually created transcripts
    for (final languageCode in languages) {
      for (final transcript in transcripts) {
        if (transcript.languageCode == languageCode &&
            !transcript.isGenerated) {
          return transcript;
        }
      }
    }

    // Then try auto-generated transcripts
    for (final languageCode in languages) {
      for (final transcript in transcripts) {
        if (transcript.languageCode == languageCode && transcript.isGenerated) {
          return transcript;
        }
      }
    }

    throw NoTranscriptFoundException(
      videoId: videoId,
      requestedLanguages: languages,
      availableLanguages:
          transcripts.map((t) => t.languageCode).toList(growable: false),
    );
  }

  /// Finds a manually created transcript matching the language preferences.
  ///
  /// [languages] - A prioritized list of language codes (e.g., ['de', 'en']).
  /// The first matching language will be returned.
  ///
  /// Throws [NoTranscriptManuallyCreatedException] if no manually created
  /// transcript is found for the requested languages.
  Transcript findManuallyCreatedTranscript(List<String> languages) {
    for (final languageCode in languages) {
      for (final transcript in transcripts) {
        if (transcript.languageCode == languageCode &&
            !transcript.isGenerated) {
          return transcript;
        }
      }
    }

    throw NoTranscriptManuallyCreatedException(
      videoId: videoId,
      requestedLanguages: languages,
      availableLanguages: transcripts
          .where((t) => !t.isGenerated)
          .map((t) => t.languageCode)
          .toList(growable: false),
    );
  }

  /// Finds an auto-generated transcript matching the language preferences.
  ///
  /// [languages] - A prioritized list of language codes (e.g., ['de', 'en']).
  /// The first matching language will be returned.
  ///
  /// Throws [NoTranscriptGeneratedException] if no auto-generated transcript
  /// is found for the requested languages.
  Transcript findGeneratedTranscript(List<String> languages) {
    for (final languageCode in languages) {
      for (final transcript in transcripts) {
        if (transcript.languageCode == languageCode && transcript.isGenerated) {
          return transcript;
        }
      }
    }

    throw NoTranscriptGeneratedException(
      videoId: videoId,
      requestedLanguages: languages,
      availableLanguages: transcripts
          .where((t) => t.isGenerated)
          .map((t) => t.languageCode)
          .toList(growable: false),
    );
  }

  @override
  String toString() {
    return 'TranscriptList(videoId: $videoId, transcripts: ${transcripts.length})';
  }
}
