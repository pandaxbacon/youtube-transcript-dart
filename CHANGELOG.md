# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2026-07-25

### Fixed

- **Webshare proxy URL format:** Fixed the proxy URL to use the correct
  `username-location-rotate` format instead of appending the country filter
  to the hostname. Added `-rotate` suffix for proper IP rotation.
- Duplicate `-rotate` suffix in username is now prevented.

### Added

- `WebshareProxyConfig` now supports multiple location filters via the
  `locations` parameter (e.g., `locations: ['DE', 'US']`).
- `WebshareProxyConfig.withLocation()` convenience constructor for single
  location backward compatibility.

## [1.0.3] - 2026-07-25

### Added

- **`Connection: close` for rotating proxies:** Added `preventKeepingConnectionsAlive`
  property to `ProxyConfig`. When true (default for `WebshareProxyConfig`), a
  `Connection: close` header is added to all requests. This ensures each request
  opens a fresh TCP connection, enabling proper IP rotation.

## [1.0.2] - 2026-07-25

### Added

- **Automatic retry on HTTP 429:** When using a proxy with `retriesWhenBlocked > 0`,
  HTTP 429 responses are now automatically retried with exponential backoff
  (1s, 2s, 4s, 8s, ...). Each retry cycles a new IP when using rotating proxies.
- `ProxyConfig.retriesWhenBlocked` property (defaults to 0 for generic proxies).
- `WebshareProxyConfig` now defaults to 10 retries and exposes a `retries` parameter.

### Changed

- `TranscriptHttpClient.get()` and `post()` now wrap request execution in a retry
  loop via `_executeWithRetry()`.

## [1.0.1] - 2026-07-25

### Added

- **Consent cookie handling:** Automatically detects and bypasses YouTube's EU consent page
  (`consent.youtube.com`). When a consent redirect is detected, the library now extracts the
  required form token and sets a `CONSENT=YES+<token>` cookie, then re-fetches the page.
- New `FailedToCreateConsentCookieException` for when consent cookie creation fails.
- Cookie storage support in `TranscriptHttpClient` with `setCookie()` method.

### Changed

- `TranscriptHttpClient` now stores cookies from `Set-Cookie` response headers and sends stored
  cookies in subsequent requests to matching domains.

## [1.0.0] - 2024-12-02

### 🎉 Initial Release

A complete Dart port of the Python youtube-transcript-api library with enhanced features.

### Added

#### Core Functionality
- 🎯 Fetch YouTube transcripts for any video without API keys
- 📝 Support for both manually created and auto-generated subtitles
- 🌍 Multiple language support with intelligent fallback
- 🔄 Translation support for available transcripts
- 🔍 List all available transcripts for a video
- 🎭 Filter by manually created or auto-generated transcripts
#### Output Formatters

- 📄 Plain text (with and without timestamps)
- 📊 JSON (simple and with full metadata)
- 📺 WebVTT (.vtt) - Standard web video format
- 🎬 SubRip (.srt) - Universal subtitle format
- 📋 CSV (.csv) - Spreadsheet-compatible format
- 🔧 Extensible formatter system for custom formats
#### Advanced Features

- 🔐 **InnerTube API Integration** - Bypasses YouTube's PoToken protection
- 🤖 Android client emulation for improved reliability
- 🌐 Proxy support:
  - Generic HTTP/HTTPS proxy configuration
  - Webshare rotating residential proxy integration
  - Custom headers and timeout configuration
- 🔄 Automatic retry logic for blocked requests
- 🚫 Comprehensive error handling with specific exceptions
#### Developer Experience

- 🎨 Null-safe, modern Dart implementation
- 📦 Clean, type-safe API design
- ⚡ Async/await throughout
- 🔁 Iterator interface for FetchedTranscript
- 🛠️ Extensive documentation and examples
- ✅ Comprehensive test suite (32 tests, 100% passing)
- 🔍 Detailed error messages with context

#### CLI Tool

- 💻 Full-featured command-line interface
- 📥 Multiple input/output formats
- 📁 File export support
- 🗂️ List available transcripts from terminal
#### Platform Support

- ✅ Dart CLI applications
- ✅ Flutter mobile apps (iOS & Android)
- ✅ Flutter web applications
- ✅ Flutter desktop (Windows, macOS, Linux)

### Technical Highlights

- 🏗️ **Architecture:** Clean separation of concerns with dedicated modules for HTTP, parsing, formatting, and models
- 🔒 **Security:** Uses defusedxml principles for safe XML parsing
- 🎯 **Reliability:** InnerTube API ensures consistent access even to protected videos
- 📈 **Performance:** Efficient parsing with minimal memory footprint
- 🧪 **Quality:** 100% of core functionality covered by tests

### Compatibility

- **Dart SDK:** >=3.0.0 <4.0.0
- **Python Library Compatibility:** Feature parity with youtube-transcript-api v1.2.3
- **YouTube API:** Uses official InnerTube API (same as YouTube mobile apps)

## [Unreleased]

### Planned
- Batch fetching for multiple videos
- Caching support to reduce API calls
- Rate limiting protection
- Cookie-based authentication for restricted videos
- Enhanced error recovery and retry logic

