import 'dart:convert';

import 'package:http/http.dart' as http;

/// A versioned study-data document as stored in the cloud. [payload] is the
/// JSON produced by `StudySnapshot.toJson`; [updatedAt] (epoch milliseconds)
/// and [deviceId] are the metadata sync uses to resolve which copy is newer
/// and where an edit came from.
class RemoteDocument {
  final Map<String, dynamic> payload;
  final int updatedAt;
  final String deviceId;

  const RemoteDocument({
    required this.payload,
    required this.updatedAt,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'updatedAt': updatedAt,
        'deviceId': deviceId,
        'payload': payload,
      };

  factory RemoteDocument.fromJson(Map<String, dynamic> json) => RemoteDocument(
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
        updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
        deviceId: (json['deviceId'] ?? '').toString(),
      );
}

/// Raised when the backend is reachable but rejects the request (auth, server
/// error, bad response). Distinct from a transport failure (offline), which
/// surfaces as the underlying [http]/socket exception so callers can treat
/// "offline" and "server said no" differently.
class CloudBackendException implements Exception {
  final String message;
  const CloudBackendException(this.message);
  @override
  String toString() => 'CloudBackendException: $message';
}

/// Abstraction over wherever study backups are stored. The app talks only to
/// this interface, so the transport (REST today) can be swapped for Firebase,
/// Supabase, etc. without touching the sync logic or UI.
abstract class CloudBackend {
  /// Whether a usable backend is configured. When false the app stays fully
  /// functional offline and the sync UI shows "not configured".
  bool get isConfigured;

  /// Fetches the stored document, or null if the user has no backup yet.
  /// Throws on transport failure (treated as "offline") or
  /// [CloudBackendException] on a server-side rejection.
  Future<RemoteDocument?> fetch();

  /// Uploads [document], overwriting any previously stored copy.
  Future<void> upload(RemoteDocument document);
}

/// Backend used when no sync endpoint is configured. Reports itself as
/// unconfigured and refuses network calls, keeping the app offline-only.
class NoopCloudBackend implements CloudBackend {
  const NoopCloudBackend();

  @override
  bool get isConfigured => false;

  @override
  Future<RemoteDocument?> fetch() async => null;

  @override
  Future<void> upload(RemoteDocument document) async {}
}

/// REST-backed store. Expects an endpoint exposing the user's document at
/// `GET/PUT {baseUrl}/users/{userId}/study-snapshot`:
///   * GET  -> 200 with a [RemoteDocument] body, or 404 when none exists yet.
///   * PUT  -> 2xx with the [RemoteDocument] as the JSON body.
/// An optional bearer [apiKey] is sent as `Authorization`.
class RestCloudBackend implements CloudBackend {
  final Uri baseUri;
  final String userId;
  final String? apiKey;
  final http.Client _client;

  RestCloudBackend({
    required this.baseUri,
    required this.userId,
    this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  bool get isConfigured => userId.isNotEmpty;

  Uri get _documentUri => baseUri.replace(
        pathSegments: [
          ...baseUri.pathSegments.where((s) => s.isNotEmpty),
          'users',
          userId,
          'study-snapshot',
        ],
      );

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (apiKey != null && apiKey!.isNotEmpty)
          'Authorization': 'Bearer $apiKey',
      };

  @override
  Future<RemoteDocument?> fetch() async {
    final response = await _client.get(_documentUri, headers: _headers);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw CloudBackendException(
        'Fetch failed (${response.statusCode}): ${response.body}',
      );
    }
    if (response.body.trim().isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CloudBackendException('Malformed document from server.');
    }
    return RemoteDocument.fromJson(decoded);
  }

  @override
  Future<void> upload(RemoteDocument document) async {
    final response = await _client.put(
      _documentUri,
      headers: _headers,
      body: jsonEncode(document.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudBackendException(
        'Upload failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
