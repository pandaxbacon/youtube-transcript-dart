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
    ..addOption(
      'batch',
      help: 'Comma-separated list of YouTube video IDs for batch fetching',
    )
    ..addOption(
      'batch-file',
      help: 'Path to file containing YouTube video IDs (one per line)',
    )
    ..addOption(
      'max-concurrent',
      help: 'Maximum number of concurrent requests for batch operations',
      defaultsTo: '5',
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
      'show-progress',
      help: 'Display progress updates for batch operations',
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

    final languages = (results['languages'] as List<String>)
        .expand((s) => s.split(','))
        .map((s) => s.trim())
        .toList();
    final maxConcurrentValue = results['max-concurrent'] as String?;
    final rawMaxConcurrent = maxConcurrentValue ?? 'missing';
    final maxConcurrent = int.tryParse(maxConcurrentValue ?? '5');
    if (maxConcurrent == null || maxConcurrent < 1) {
      throw FormatException(
        'Invalid value for --max-concurrent: $rawMaxConcurrent '
        '(must be a positive integer)',
      );
    }

    final batchArg = results['batch'] as String?;
    final batchFile = results['batch-file'] as String?;
    final showProgress = results['show-progress'] as bool;
    final format = results['format'] as String;
    final outputPath = results['output'] as String?;
    final preserveFormatting = results['preserve-formatting'] as bool;

    final api = YouTubeTranscriptApi();

    try {
      if (batchArg != null || batchFile != null) {
        final batchVideoIds = await _resolveBatchVideoIds(batchArg, batchFile);

        if (batchVideoIds.isEmpty) {
          stderr.writeln('Error: No video IDs provided for batch fetch');
          exit(1);
        }

        await _fetchBatchTranscripts(
          api,
          batchVideoIds,
          languages: languages,
          format: format,
          outputPath: outputPath,
          preserveFormatting: preserveFormatting,
          showProgress: showProgress,
          maxConcurrent: maxConcurrent,
        );
        return;
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

      if (results['list'] as bool) {
        await _listTranscripts(api, videoId);
      } else {
        await _fetchTranscript(
          api,
          videoId,
          languages: languages,
          format: format,
          outputPath: outputPath,
          manualOnly: results['manual-only'] as bool,
          generatedOnly: results['generated-only'] as bool,
          preserveFormatting: preserveFormatting,
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
  print(
    'Usage: youtube_transcript_api [options] <video-id>'
    ' | --batch <ids> | --batch-file <path>',
  );
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
  print('');
  print('  # Fetch multiple videos and save to directory');
  print(
    '  youtube_transcript_api --batch dQw4w9WgXcQ,6-87bwBCyos'
    ' -o transcripts/',
  );
  print('');
  print('  # Fetch from file with progress updates');
  print('  youtube_transcript_api --batch-file video_ids.txt --show-progress');
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

Future<List<String>> _resolveBatchVideoIds(
  String? batchArg,
  String? batchFile,
) async {
  final videoIds = <String>[];

  if (batchArg != null && batchArg.isNotEmpty) {
    videoIds.addAll(
      batchArg.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty),
    );
  }

  if (batchFile != null) {
    final file = File(batchFile);
    if (!await file.exists()) {
      throw FormatException('Batch file not found: $batchFile');
    }

    final lines = await file.readAsLines();
    videoIds.addAll(
      lines.map((line) => line.trim()).where((line) => line.isNotEmpty),
    );
  }

  return videoIds;
}

Future<void> _fetchBatchTranscripts(
  YouTubeTranscriptApi api,
  List<String> videoIds, {
  required List<String> languages,
  required String format,
  String? outputPath,
  bool preserveFormatting = false,
  bool showProgress = false,
  required int maxConcurrent,
}) async {
  final progress = showProgress
      ? (int completed, int total) {
          stdout.writeln('Progress: $completed/$total');
        }
      : null;

  final results = await api.fetchBatch(
    videoIds,
    languages: languages,
    preserveFormatting: preserveFormatting,
    maxConcurrent: maxConcurrent,
    onProgress: progress,
  );

  Directory? outputDirectory;
  if (outputPath != null) {
    outputDirectory = Directory(outputPath);
    await outputDirectory.create(recursive: true);
  }

  for (final entry in results.entries) {
    final videoId = entry.key;
    final result = entry.value;

    if (result.isSuccess) {
      final formatted = _formatTranscript(result.transcript!, format);
      if (outputDirectory != null) {
        final filePath = _buildOutputPath(
          outputDirectory.path,
          videoId,
          format,
        );
        await File(filePath).writeAsString(formatted);
        stdout.writeln('Transcript saved to: $filePath');
      } else {
        stdout.writeln('=== Transcript for $videoId ===');
        stdout.writeln(formatted);
      }
    } else {
      stderr.writeln('Error for $videoId: ${result.error}');
    }
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

String _buildOutputPath(String directoryPath, String videoId, String format) {
  final normalized = directoryPath.endsWith(Platform.pathSeparator)
      ? directoryPath
      : '$directoryPath${Platform.pathSeparator}';
  final extension = _formatExtension(format);
  return '$normalized$videoId.$extension';
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

String _formatExtension(String format) {
  switch (format) {
    case 'json':
    case 'json-meta':
      return 'json';
    case 'vtt':
      return 'vtt';
    case 'srt':
      return 'srt';
    case 'csv':
      return 'csv';
    default:
      return 'txt';
  }
}
