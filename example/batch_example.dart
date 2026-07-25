import 'package:youtube_transcript_api/youtube_transcript_api.dart';

Future<void> main() async {
  final api = YouTubeTranscriptApi();

  final results = await api.fetchBatch(
    ['dQw4w9WgXcQ', '6-87bwBCyos', 'jNQXAC9IVRw'],
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

  api.dispose();
}
