import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'cloud_backend.dart';

/// Resolves cloud-sync configuration and builds the matching [CloudBackend].
///
/// Configuration is read from (in order of precedence) compile-time
/// `--dart-define`s and then a loaded `.env` file:
///   * `SYNC_API_URL` — base URL of the sync service. When absent, sync is
///     considered unconfigured and a [NoopCloudBackend] is returned so the app
///     runs offline-only.
///   * `SYNC_USER_ID`  — identifies whose backup to read/write.
///   * `SYNC_API_KEY`  — optional bearer token.
class SyncConfig {
  final String apiUrl;
  final String userId;
  final String apiKey;

  const SyncConfig({
    required this.apiUrl,
    required this.userId,
    required this.apiKey,
  });

  bool get isConfigured => apiUrl.isNotEmpty;

  static String _read(String key) {
    // Compile-time define wins so a build can hard-wire its endpoint.
    const defines = {
      'SYNC_API_URL': String.fromEnvironment('SYNC_API_URL'),
      'SYNC_USER_ID': String.fromEnvironment('SYNC_USER_ID'),
      'SYNC_API_KEY': String.fromEnvironment('SYNC_API_KEY'),
    };
    final fromDefine = defines[key];
    if (fromDefine != null && fromDefine.isNotEmpty) return fromDefine;

    // Fall back to a .env file if one was loaded. dotenv throws when it has not
    // been initialised, so guard against that — a missing .env just means
    // "unconfigured", not a crash.
    try {
      if (dotenv.isInitialized) return dotenv.env[key] ?? '';
    } catch (_) {/* dotenv not initialised */}
    return '';
  }

  factory SyncConfig.fromEnvironment() => SyncConfig(
        apiUrl: _read('SYNC_API_URL'),
        userId: _read('SYNC_USER_ID'),
        apiKey: _read('SYNC_API_KEY'),
      );

  /// Builds the backend described by this config, or a [NoopCloudBackend] when
  /// no endpoint is set.
  CloudBackend buildBackend() {
    if (!isConfigured) return const NoopCloudBackend();
    final uri = Uri.tryParse(apiUrl);
    if (uri == null || !uri.hasScheme) return const NoopCloudBackend();
    return RestCloudBackend(
      baseUri: uri,
      // Fall back to a stable shared id so a configured endpoint without an
      // explicit user still round-trips a single backup.
      userId: userId.isNotEmpty ? userId : 'default',
      apiKey: apiKey,
    );
  }
}
