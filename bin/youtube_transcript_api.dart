#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'video-id',
      abbr: 'v',
      help: 'YouTube video ID (e.g., dQw4w9WgXcQ)',
      mandatory: false,
    )
    ..addMultiOption(
      'languages',
      abbr: 'l',
      help: 'Comma-separated list of language codes (e.g., en,de)',
      defaultsTo: ['en'],
    )
    ..addOption(
      'format',
      abbr: 'f',
      help: 'Output format: text, json, vtt, srt, csv',
      defaultsTo: 'text',
      allowed: ['text', 'text-ts', 'json', 'json-meta', 'vtt', 'srt', 'csv'],
    )
    ..addOption('output', abbr: 'o', help: 'Output file path (default: stdout)')
    ..addFlag(
      'list',
      help: 'List all available transcripts for the video',
      negatable: false,
    )
    ..addFlag(
      'manual-only',
      help: 'Only fetch manually created transcripts',
      negatable: false,
    )
    ..addFlag(
      'generated-only',
      help: 'Only fetch auto-generated transcripts',
      negatable: false,
    )
    ..addFlag(
      'preserve-formatting',
      help: 'Preserve HTML formatting in transcript text',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printUsage(parser);
      exit(0);
    }

    // Get video ID from option or positional argument
    String? videoId = results['video-id'] as String?;
    if (videoId == null && results.rest.isNotEmpty) {
      videoId = results.rest.first;
    }

    if (videoId == null) {
      stderr.writeln('Error: Video ID is required');
      _printUsage(parser);
      exit(1);
    }

    final api = YouTubeTranscriptApi();
    final languages = (results['languages'] as List<String>)
        .expand((s) => s.split(','))
        .map((s) => s.trim())
        .toList();

    try {
      if (results['list'] as bool) {
        await _listTranscripts(api, videoId);
      } else {
        await _fetchTranscript(
          api,
          videoId,
          languages: languages,
          format: results['format'] as String,
          outputPath: results['output'] as String?,
          manualOnly: results['manual-only'] as bool,
          generatedOnly: results['generated-only'] as bool,
          preserveFormatting: results['preserve-formatting'] as bool,
        );
      }
    } finally {
      api.dispose();
    }
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    _printUsage(parser);
    exit(1);
  } on TranscriptException catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  } catch (e) {
    stderr.writeln('Unexpected error: $e');
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('YouTube Transcript API CLI');
  print('');
  print('Usage: youtube_transcript_api [options] <video-id>');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Examples:');
  print('  # Fetch English transcript as plain text');
  print('  youtube_transcript_api dQw4w9WgXcQ');
  print('');
  print('  # Fetch German transcript as JSON');
  print('  youtube_transcript_api -v dQw4w9WgXcQ -l de -f json');
  print('');
  print('  # List all available transcripts');
  print('  youtube_transcript_api -v dQw4w9WgXcQ --list');
  print('');
  print('  # Save transcript as SRT file');
  print('  youtube_transcript_api dQw4w9WgXcQ -f srt -o output.srt');
}

Future<void> _listTranscripts(YouTubeTranscriptApi api, String videoId) async {
  print('Fetching available transcripts for video: $videoId');
  print('');

  final transcriptList = await api.list(videoId);

  if (transcriptList.isEmpty) {
    print('No transcripts available for this video.');
    return;
  }

  print('Available transcripts:');
  print('');

  for (final transcript in transcriptList) {
    final type = transcript.isGenerated ? 'Auto-generated' : 'Manual';
    final translatable =
        transcript.isTranslatable ? '(translatable)' : '(not translatable)';

    print('  - ${transcript.language} [${transcript.languageCode}]');
    print('    Type: $type $translatable');

    if (transcript.translationLanguages.isNotEmpty) {
      final langs = transcript.translationLanguages
          .take(5)
          .map((l) => l.languageCode)
          .join(', ');
      final more = transcript.translationLanguages.length > 5
          ? ' and ${transcript.translationLanguages.length - 5} more'
          : '';
      print('    Can translate to: $langs$more');
    }
    print('');
  }
}

Future<void> _fetchTranscript(
  YouTubeTranscriptApi api,
  String videoId, {
  required List<String> languages,
  required String format,
  String? outputPath,
  bool manualOnly = false,
  bool generatedOnly = false,
  bool preserveFormatting = false,
}) async {
  // Fetch the appropriate transcript
  Transcript transcript;

  if (manualOnly && generatedOnly) {
    stderr.writeln(
      'Error: Cannot specify both --manual-only and --generated-only',
    );
    exit(1);
  }

  final transcriptList = await api.list(videoId);

  if (manualOnly) {
    transcript = transcriptList.findManuallyCreatedTranscript(languages);
  } else if (generatedOnly) {
    transcript = transcriptList.findGeneratedTranscript(languages);
  } else {
    transcript = transcriptList.findTranscript(languages);
  }

  // Fetch the transcript content
  final fetchedTranscript = await transcript.fetch(
    preserveFormatting: preserveFormatting,
  );

  // Format the transcript
  final formatted = _formatTranscript(fetchedTranscript, format);

  // Output the result
  if (outputPath != null) {
    await File(outputPath).writeAsString(formatted);
    print('Transcript saved to: $outputPath');
  } else {
    print(formatted);
  }
}

String _formatTranscript(FetchedTranscript transcript, String format) {
  switch (format) {
    case 'text':
      return TextFormatter().format(transcript);
    case 'text-ts':
      return TextFormatterWithTimestamps().format(transcript);
    case 'json':
      return JsonFormatter(pretty: true).format(transcript);
    case 'json-meta':
      return JsonFormatterWithMetadata(pretty: true).format(transcript);
    case 'vtt':
      return VttFormatter().format(transcript);
    case 'srt':
      return SrtFormatter().format(transcript);
    case 'csv':
      return CsvFormatter().format(transcript);
    default:
      throw ArgumentError('Unknown format: $format');
  }
}
