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
    ..addOption(
      'translate',
      help: 'Translate transcript to the given language code',
    )
    ..addFlag(
      'preserve-formatting',
      help: 'Preserve HTML formatting in transcript text',
      negatable: false,
    )
    ..addOption(
      'http-proxy',
      help: 'HTTP proxy URL (e.g., http://user:pass@proxy:8080)',
    )
    ..addOption(
      'https-proxy',
      help: 'HTTPS proxy URL (e.g., https://user:pass@proxy:8443)',
    )
    ..addOption(
      'webshare-proxy-username',
      help: 'Webshare proxy username (from dashboard.webshare.io)',
    )
    ..addOption(
      'webshare-proxy-password',
      help: 'Webshare proxy password (from dashboard.webshare.io)',
    )
    ..addOption(
      'cookies',
      help:
          '(Currently unsupported) Path to cookies.txt file for authentication',
    )
    ..addFlag(
      'version',
      help: 'Show version number',
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

    if (results['version'] as bool) {
      print('youtube_transcript_api version 1.0.7');
      exit(0);
    }

    // Collect video IDs from both --video-id option and positional args
    final videoIds = <String>[];
    final optVideoId = results['video-id'] as String?;
    if (optVideoId != null) videoIds.add(optVideoId);
    videoIds.addAll(results.rest);

    if (videoIds.isEmpty) {
      stderr.writeln('Error: At least one video ID is required');
      _printUsage(parser);
      exit(1);
    }

    // Strip backslash escaping from video IDs (e.g., "\-abc123" → "-abc123")
    final sanitizedIds = videoIds.map((id) => id.replaceAll('\\', '')).toList();

    // Build proxy config if requested
    final proxyConfig = _buildProxyConfig(results);

    final api = YouTubeTranscriptApi(proxyConfig: proxyConfig);
    final languages = (results['languages'] as List<String>)
        .expand((s) => s.split(','))
        .map((s) => s.trim())
        .toList();

    try {
      final isListMode = results['list'] as bool;

      if (results['cookies'] != null) {
        stderr.writeln(
          'Warning: Cookie-based authentication is not currently supported. '
          'The --cookies flag is reserved for future use.',
        );
      }

      final transcripts = <FetchedTranscript>[];
      final errors = <String>[];

      for (final videoId in sanitizedIds) {
        try {
          final transcriptList = await api.list(videoId);

          if (isListMode) {
            print('Transcripts for $videoId:');
            print(transcriptList);
            print('');
          } else {
            final transcript = await _fetchTranscript(
              transcriptList,
              languages: languages,
              manualOnly: results['manual-only'] as bool,
              generatedOnly: results['generated-only'] as bool,
              translateTo: results['translate'] as String?,
            );
            transcripts.add(transcript);
          }
        } on TranscriptException catch (e) {
          errors.add('$videoId: $e');
        }
      }

      // Print errors
      for (final error in errors) {
        stderr.writeln('Error: $error');
      }

      // Format and output transcripts
      if (!isListMode && transcripts.isNotEmpty) {
        final formatted = _formatTranscripts(
          transcripts,
          results['format'] as String,
        );

        final outputPath = results['output'] as String?;
        if (outputPath != null) {
          await File(outputPath).writeAsString(formatted);
          print('Transcript saved to: $outputPath');
        } else {
          print(formatted);
        }
      }
    } finally {
      api.dispose();
    }
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    _printUsage(parser);
    exit(1);
  } catch (e) {
    stderr.writeln('Unexpected error: $e');
    exit(1);
  }
}

ProxyConfig? _buildProxyConfig(ArgResults results) {
  final httpProxy = results['http-proxy'] as String?;
  final httpsProxy = results['https-proxy'] as String?;

  if (httpProxy != null || httpsProxy != null) {
    return GenericProxyConfig(httpUrl: httpProxy, httpsUrl: httpsProxy);
  }

  final wsUsername = results['webshare-proxy-username'] as String?;
  final wsPassword = results['webshare-proxy-password'] as String?;

  if (wsUsername != null && wsPassword != null) {
    return WebshareProxyConfig(username: wsUsername, password: wsPassword);
  }

  return null;
}

Future<FetchedTranscript> _fetchTranscript(
  TranscriptList transcriptList, {
  required List<String> languages,
  bool manualOnly = false,
  bool generatedOnly = false,
  String? translateTo,
}) async {
  if (manualOnly && generatedOnly) {
    throw ArgumentError(
      'Cannot specify both --manual-only and --generated-only',
    );
  }

  Transcript transcript;

  if (manualOnly) {
    transcript = transcriptList.findManuallyCreatedTranscript(languages);
  } else if (generatedOnly) {
    transcript = transcriptList.findGeneratedTranscript(languages);
  } else {
    transcript = transcriptList.findTranscript(languages);
  }

  // Translate if requested
  if (translateTo != null) {
    transcript = transcript.translate(translateTo);
  }

  return await transcript.fetch();
}

String _formatTranscripts(List<FetchedTranscript> transcripts, String format) {
  switch (format) {
    case 'text':
      return transcripts.map((t) => TextFormatter().format(t)).join('\n\n\n');
    case 'text-ts':
      return transcripts
          .map((t) => TextFormatterWithTimestamps().format(t))
          .join('\n\n\n');
    case 'json':
      return transcripts
          .map((t) => JsonFormatter(pretty: true).format(t))
          .join('\n,\n');
    case 'json-meta':
      return transcripts
          .map((t) => JsonFormatterWithMetadata(pretty: true).format(t))
          .join('\n,\n');
    case 'vtt':
      return transcripts.map((t) => VttFormatter().format(t)).join('\n');
    case 'srt':
      return transcripts.map((t) => SrtFormatter().format(t)).join('\n');
    case 'csv':
      return transcripts.map((t) => CsvFormatter().format(t)).join('\n');
    default:
      throw ArgumentError('Unknown format: $format');
  }
}

void _printUsage(ArgParser parser) {
  print('YouTube Transcript API CLI');
  print('');
  print('Usage: youtube_transcript_api [options] <video-id> [<video-id> ...]');
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
  print('  # Translate to German');
  print('  youtube_transcript_api dQw4w9WgXcQ --translate de');
  print('');
  print('  # List all available transcripts');
  print('  youtube_transcript_api -v dQw4w9WgXcQ --list');
  print('');
  print('  # Fetch multiple videos');
  print('  youtube_transcript_api dQw4w9WgXcQ video2-id video3-id');
  print('');
  print('  # Use a proxy');
  print(
    '  youtube_transcript_api dQw4w9WgXcQ --http-proxy http://user:pass@proxy:8080',
  );
  print('');
  print('  # Use Webshare proxy');
  print(
    '  youtube_transcript_api dQw4w9WgXcQ --webshare-proxy-username myuser --webshare-proxy-password mypass',
  );
  print('');
  print('  # Save transcript as SRT file');
  print('  youtube_transcript_api dQw4w9WgXcQ -f srt -o output.srt');
}
