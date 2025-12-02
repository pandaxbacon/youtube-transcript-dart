import 'package:youtube_transcript_api/youtube_transcript_api.dart';

/// Example demonstrating the basic usage of the YouTube Transcript API.
void main() async {
  await basicExample();
  print('\n---\n');
  await listTranscriptsExample();
  print('\n---\n');
  await formatterExample();
  print('\n---\n');
  await proxyExample();
}

/// Basic example: Fetch a transcript
Future<void> basicExample() async {
  print('=== Basic Example ===\n');

  final api = YouTubeTranscriptApi();

  try {
    // Fetch transcript (replace with a real video ID)
    print('Fetching transcript...');
    final transcript = await api.fetch('dQw4w9WgXcQ', languages: ['en']);

    print('Video ID: ${transcript.videoId}');
    print('Language: ${transcript.language}');
    print('Snippets: ${transcript.snippets.length}');
    print('\nFirst 3 snippets:');

    // Print first 3 snippets
    for (var snippet in transcript.snippets.take(3)) {
      print('[${snippet.start.toStringAsFixed(2)}s] ${snippet.text}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    api.dispose();
  }
}

/// List all available transcripts for a video
Future<void> listTranscriptsExample() async {
  print('=== List Transcripts Example ===\n');

  final api = YouTubeTranscriptApi();

  try {
    print('Listing available transcripts...');
    final transcriptList = await api.list('dQw4w9WgXcQ');

    print('Found ${transcriptList.length} transcript(s):\n');

    for (var transcript in transcriptList) {
      print('${transcript.language} [${transcript.languageCode}]');
      print('  Type: ${transcript.isGenerated ? "Auto-generated" : "Manual"}');
      print('  Translatable: ${transcript.isTranslatable}');

      if (transcript.isTranslatable) {
        final langs = transcript.translationLanguages
            .take(3)
            .map((l) => l.languageCode)
            .join(', ');
        print('  Can translate to: $langs...');
      }
      print('');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    api.dispose();
  }
}

/// Example using different formatters
Future<void> formatterExample() async {
  print('=== Formatter Example ===\n');

  final api = YouTubeTranscriptApi();

  try {
    final transcript = await api.fetch('dQw4w9WgXcQ', languages: ['en']);

    // Text formatter
    print('Text Format:');
    final textFormatter = TextFormatter();
    final text = textFormatter.format(transcript);
    print(text.split('\n').take(3).join('\n'));
    print('...\n');

    // JSON formatter
    print('JSON Format:');
    final jsonFormatter = JsonFormatter(pretty: true);
    final json = jsonFormatter.format(transcript);
    print(json.split('\n').take(10).join('\n'));
    print('...\n');

    // VTT formatter
    print('WebVTT Format:');
    final vttFormatter = VttFormatter();
    final vtt = vttFormatter.format(transcript);
    print(vtt.split('\n').take(8).join('\n'));
    print('...\n');

    // SRT formatter
    print('SRT Format:');
    final srtFormatter = SrtFormatter();
    final srt = srtFormatter.format(transcript);
    print(srt.split('\n').take(6).join('\n'));
    print('...\n');
  } catch (e) {
    print('Error: $e');
  } finally {
    api.dispose();
  }
}

/// Example using proxy configuration
Future<void> proxyExample() async {
  print('=== Proxy Example ===\n');

  // Example 1: Generic proxy
  print('Using generic proxy configuration:');
  var api = YouTubeTranscriptApi(
    proxyConfig: GenericProxyConfig(
      httpUrl: 'http://proxy.example.com:8080',
      httpsUrl: 'https://proxy.example.com:8443',
    ),
  );
  print('Configured with generic proxy\n');
  api.dispose();

  // Example 2: Webshare proxy
  print('Using Webshare proxy configuration:');
  api = YouTubeTranscriptApi(
    proxyConfig: WebshareProxyConfig(
      username: 'your-username',
      password: 'your-password',
      location: 'US',
    ),
  );
  print('Configured with Webshare proxy\n');
  api.dispose();

  print('Note: These are just configuration examples.');
  print('Actual proxy usage would require valid credentials.');
}
