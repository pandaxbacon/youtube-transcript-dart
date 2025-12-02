/// YouTube API settings and constants.
library;

/// The watch URL for YouTube videos.
const String watchUrl = 'https://www.youtube.com/watch?v={video_id}';

/// The InnerTube API endpoint URL.
const String innertubeApiUrl =
    'https://www.youtube.com/youtubei/v1/player?key={api_key}';

/// The InnerTube context to use for API requests.
///
/// We pretend to be an Android client to avoid certain YouTube restrictions
/// and anti-bot measures like PoToken requirements.
const Map<String, dynamic> innertubeContext = {
  'client': {'clientName': 'ANDROID', 'clientVersion': '20.10.38'},
};

/// Regular expression pattern to extract the InnerTube API key from HTML.
final RegExp innertubeApiKeyPattern = RegExp(
  r'"INNERTUBE_API_KEY":\s*"([a-zA-Z0-9_-]+)"',
);
