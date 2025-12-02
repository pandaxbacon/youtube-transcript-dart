/// Tool to capture real YouTube responses for use in tests.
/// Run this once to generate test fixtures.
library;

import 'dart:convert';
import 'dart:io';
import 'package:youtube_transcript_api/src/http/http_client.dart';
import 'package:youtube_transcript_api/src/settings.dart';

Future<void> main() async {
  final videoId = 'eF8Qqp7rjDg'; // Your test video
  final httpClient = TranscriptHttpClient();

  try {
    print('Capturing responses for video: $videoId\n');

    // 1. Capture HTML page
    print('1. Fetching YouTube HTML page...');
    final videoUrl = watchUrl.replaceAll('{video_id}', videoId);
    final htmlResponse = await httpClient.get(videoUrl);
    await File(
      'test/fixtures/youtube_page.html',
    ).writeAsString(htmlResponse.body);
    print('   ✅ Saved to: test/fixtures/youtube_page.html\n');

    // 2. Extract API key and capture InnerTube response
    print('2. Extracting InnerTube API key...');
    final match = innertubeApiKeyPattern.firstMatch(htmlResponse.body);
    final apiKey = match?.group(1);
    print('   ✅ API Key: $apiKey\n');

    print('3. Fetching InnerTube API response...');
    final innertubeUrl = innertubeApiUrl.replaceAll('{api_key}', apiKey!);
    final innertubeResponse = await httpClient.post(
      innertubeUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'context': innertubeContext, 'videoId': videoId}),
    );

    // Save pretty-printed JSON
    final innertubeData = json.decode(innertubeResponse.body);
    final prettyJson = JsonEncoder.withIndent('  ').convert(innertubeData);
    await File(
      'test/fixtures/innertube_response.json',
    ).writeAsString(prettyJson);
    print('   ✅ Saved to: test/fixtures/innertube_response.json\n');

    // 3. Capture transcript XML
    print('4. Extracting transcript URL...');
    final captions = innertubeData['captions'] as Map<String, dynamic>;
    final renderer =
        captions['playerCaptionsTracklistRenderer'] as Map<String, dynamic>;
    final tracks = renderer['captionTracks'] as List<dynamic>;
    final firstTrack = tracks.first as Map<String, dynamic>;
    final transcriptUrl = (firstTrack['baseUrl'] as String).replaceAll(
      '&fmt=srv3',
      '',
    );

    print('   URL: ${transcriptUrl.substring(0, 80)}...\n');

    print('5. Fetching transcript XML...');
    final transcriptResponse = await httpClient.get(transcriptUrl);
    await File(
      'test/fixtures/transcript.xml',
    ).writeAsString(transcriptResponse.body);
    print('   ✅ Saved to: test/fixtures/transcript.xml\n');

    print('═══════════════════════════════════════════════════════════');
    print('✅ All fixtures captured successfully!');
    print('═══════════════════════════════════════════════════════════');
    print('\nYou can now use these files in your tests to avoid');
    print('hitting the real YouTube API.');
  } catch (e, stack) {
    print('❌ Error: $e');
    print(stack);
  } finally {
    httpClient.close();
  }
}
