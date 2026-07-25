# ✨ YouTube Transcript API (Dart) ✨

[![Pub Version](https://img.shields.io/pub/v/youtube_transcript_api?color=blue)](https://pub.dev/packages/youtube_transcript_api)
[![Dart CI](https://github.com/pandaxbacon/youtube-transcript-dart/workflows/Dart%20CI/badge.svg)](https://github.com/pandaxbacon/youtube-transcript-dart/actions)
[![Coverage](https://img.shields.io/codecov/c/github/pandaxbacon/youtube-transcript-dart)](https://codecov.io/gh/pandaxbacon/youtube-transcript-dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart Version](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue)](https://dart.dev)

**A Dart library to fetch YouTube transcripts and subtitles. Works with auto-generated and manually created transcripts. No API key required!**

This is a Dart port of the popular Python library [youtube-transcript-api](https://github.com/jdepoix/youtube-transcript-api).

## Features

- ✅ Fetch transcripts for any YouTube video
- ✅ Support for both manually created and auto-generated subtitles
- ✅ Multiple language support with automatic fallback
- ✅ Translation support for available transcripts
- ✅ Multiple output formats (Text, JSON, WebVTT, SRT, CSV)
- ✅ Batch/bulk fetching for multiple videos and playlists
- ✅ Proxy support (including Webshare rotating proxies)
- ✅ No API key required
- ✅ Works in both Dart and Flutter applications
- ✅ Command-line interface included
- ✅ Bypasses YouTube's PoToken protection using InnerTube API

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  youtube_transcript_api: ^1.0.0
```

Then run:

```bash
dart pub get
```

Or for Flutter:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

void main() async {
  final api = YouTubeTranscriptApi();
  
  try {
    // Fetch transcript for a video
    final transcript = await api.fetch('dQw4w9WgXcQ');
    
    // Print each snippet
    for (var snippet in transcript) {
      print('[${snippet.start}] ${snippet.text}');
    }
  } finally {
    api.dispose();
  }
}
```

## Usage

### Fetch Transcripts with Language Preference

```dart
// Try to fetch German transcript, fallback to English
final transcript = await api.fetch(
  'dQw4w9WgXcQ',
  languages: ['de', 'en'],
);
```

### List Available Transcripts

```dart
final transcriptList = await api.list('dQw4w9WgXcQ');

for (var transcript in transcriptList) {
  print('${transcript.language} [${transcript.languageCode}]');
  print('  Generated: ${transcript.isGenerated}');
  print('  Translatable: ${transcript.isTranslatable}');
}
```

### Find Specific Transcript Types

```dart
// Find manually created transcript
final manual = await api.findManuallyCreatedTranscript(
  'dQw4w9WgXcQ',
  ['en'],
);

// Find auto-generated transcript
final generated = await api.findGeneratedTranscript(
  'dQw4w9WgXcQ',
  ['en'],
);
```

### Translate Transcripts

```dart
final transcriptList = await api.list('dQw4w9WgXcQ');
final transcript = transcriptList.findTranscript(['en']);

// Translate to German
final germanTranscript = transcript.translate('de');
final fetched = await germanTranscript.fetch();
```

### Using Formatters

```dart
final transcript = await api.fetch('dQw4w9WgXcQ');

// Plain text
final textFormatter = TextFormatter();
print(textFormatter.format(transcript));

// JSON
final jsonFormatter = JsonFormatter(pretty: true);
print(jsonFormatter.format(transcript));

// WebVTT
final vttFormatter = VttFormatter();
print(vttFormatter.format(transcript));

// SRT
final srtFormatter = SrtFormatter();
print(srtFormatter.format(transcript));

// CSV
final csvFormatter = CsvFormatter();
print(csvFormatter.format(transcript));
```

### Batch Fetching

```dart
final results = await api.fetchBatch(
  [
    'dQw4w9WgXcQ',
    '6-87bwBCyos',
    'jNQXAC9IVRw',
  ],
  maxConcurrent: 3,
  onProgress: (completed, total) {
    print('Progress: $completed/$total');
  },
);

for (final entry in results.entries) {
  final videoId = entry.key;
  final result = entry.value;

  if (result.isSuccess) {
    print('✅ $videoId: ${result.transcript!.snippets.length} snippets');
  } else {
    print('❌ $videoId: ${result.error}');
  }
}
```

### Playlist Fetching

```dart
final playlistResults = await api.fetchPlaylist(
  'https://www.youtube.com/playlist?list=PLAYLIST_ID',
  maxVideos: 10,
  maxConcurrent: 2,
  onProgress: (completed, total) {
    print('Progress: $completed/$total');
  },
);
```

### Using Proxies

#### Generic Proxy

```dart
final api = YouTubeTranscriptApi(
  proxyConfig: GenericProxyConfig(
    httpUrl: 'http://proxy.example.com:8080',
    httpsUrl: 'https://proxy.example.com:8443',
  ),
);
```

#### Webshare Rotating Proxy

```dart
final api = YouTubeTranscriptApi(
  proxyConfig: WebshareProxyConfig(
    username: 'your-username',
    password: 'your-password',
    location: 'US', // Optional location filter
  ),
);
```

## Command-Line Interface

### Installation

Activate the package globally:

```bash
dart pub global activate youtube_transcript_api
```

### Usage

```bash
# Fetch transcript as plain text
youtube_transcript_api dQw4w9WgXcQ

# Fetch in specific language
youtube_transcript_api dQw4w9WgXcQ -l de

# List available transcripts
youtube_transcript_api dQw4w9WgXcQ --list

# Save as JSON file
youtube_transcript_api dQw4w9WgXcQ -f json -o transcript.json

# Save as SRT subtitle file
youtube_transcript_api dQw4w9WgXcQ -f srt -o subtitle.srt

# Multiple languages with fallback
youtube_transcript_api dQw4w9WgXcQ -l de,en,fr

# Fetch multiple videos and save to a directory
youtube_transcript_api --batch dQw4w9WgXcQ,6-87bwBCyos -o transcripts/ --show-progress

# Fetch from a file of video IDs with limited concurrency
youtube_transcript_api --batch-file video_ids.txt --max-concurrent 3 -f json
```

### CLI Options

```
-v, --video-id          YouTube video ID
-l, --languages         Comma-separated language codes (default: en)
-f, --format            Output format: text, json, vtt, srt, csv
                        (default: text)
-o, --output            Output file path (default: stdout)
    --list              List all available transcripts
    --manual-only       Only fetch manually created transcripts
    --generated-only    Only fetch auto-generated transcripts
    --preserve-formatting   Preserve HTML formatting in text
-h, --help              Show help message
```

## Exception Handling

The library provides detailed exceptions for different error scenarios:

```dart
try {
  final transcript = await api.fetch('video-id');
} on VideoUnavailableException catch (e) {
  print('Video not available: ${e.videoId}');
} on TranscriptsDisabledException catch (e) {
  print('Transcripts are disabled for this video');
} on NoTranscriptFoundException catch (e) {
  print('No transcript found for languages: ${e.requestedLanguages}');
  print('Available languages: ${e.availableLanguages}');
} on TooManyRequestsException catch (e) {
  print('Rate limited by YouTube. Consider using a proxy.');
} on IpBlockedException catch (e) {
  print('IP blocked by YouTube. Use a proxy.');
} on TranscriptException catch (e) {
  print('General error: $e');
}
```

## Advanced Features

### InnerTube API Integration

This library uses YouTube's InnerTube API to bypass PoToken protection and access transcripts reliably. It pretends to be an Android client, which helps avoid bot detection and rate limiting.

### Custom Headers and Timeout

```dart
final api = YouTubeTranscriptApi(
  headers: {
    'User-Agent': 'MyCustomAgent/1.0',
  },
  timeout: Duration(seconds: 60),
);
```

## Limitations

- YouTube may rate-limit or block requests from certain IP addresses. Consider using proxies if you encounter issues.
- The library relies on YouTube's internal API, which may change without notice.
- Some videos may not have transcripts available.
- Private or age-restricted videos may not be accessible.

## Platform Support

| Platform | Status |
|----------|--------|
| ✅ Android | Fully supported |
| ✅ iOS | Fully supported |
| ✅ Web | Fully supported |
| ✅ Windows | Fully supported |
| ✅ macOS | Fully supported |
| ✅ Linux | Fully supported |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- Inspired by and based on the Python [youtube-transcript-api](https://github.com/jdepoix/youtube-transcript-api) by [jdepoix](https://github.com/jdepoix)
- Ported to Dart with InnerTube API integration for improved reliability

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed changelog.

## Support

- 📖 Documentation: See [QUICK_START.md](QUICK_START.md)
- 💻 Examples: Check the [example](example/) directory
- 🐛 Issues: Report on [GitHub Issues](https://github.com/pandaxbacon/youtube-transcript-dart/issues)
- 💬 Discussions: Join [GitHub Discussions](https://github.com/pandaxbacon/youtube-transcript-dart/discussions)

---

**Made with ❤️ for the Dart & Flutter community**

If you find this package useful, please consider giving it a ⭐ on [GitHub](https://github.com/pandaxbacon/youtube-transcript-dart)!
