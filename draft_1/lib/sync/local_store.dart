import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'study_snapshot.dart';

/// Local, on-device persistence for the study snapshot plus the small amount of
/// sync bookkeeping the [SyncService] needs. Backed by SharedPreferences (the
/// same mechanism the theme uses), this is what makes the app's data survive
/// app restarts and work fully offline — cloud sync is layered on top of it.
class LocalStore {
  static const _kSnapshot = 'sync.snapshot';
  static const _kLocalUpdatedAt = 'sync.localUpdatedAt';
  static const _kLastSyncedUpdatedAt = 'sync.lastSyncedUpdatedAt';
  static const _kEnabled = 'sync.enabled';
  static const _kPending = 'sync.pending';
  static const _kDeviceId = 'sync.deviceId';

  final SharedPreferences _prefs;
  LocalStore(this._prefs);

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  // --- Snapshot -------------------------------------------------------------

  /// The locally-persisted snapshot, or null if nothing has been saved yet
  /// (first launch). A corrupt payload is treated as "nothing saved" rather
  /// than crashing startup.
  StudySnapshot? loadSnapshot() {
    final raw = _prefs.getString(_kSnapshot);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return StudySnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSnapshot(StudySnapshot snapshot) =>
      _prefs.setString(_kSnapshot, jsonEncode(snapshot.toJson()));

  // --- Sync bookkeeping -----------------------------------------------------

  /// Epoch millis of the most recent local change.
  int get localUpdatedAt => _prefs.getInt(_kLocalUpdatedAt) ?? 0;
  Future<void> setLocalUpdatedAt(int value) =>
      _prefs.setInt(_kLocalUpdatedAt, value);

  /// [localUpdatedAt] of the copy we last reconciled with the cloud. Lets us
  /// tell a fresh local edit apart from data we already pushed.
  int get lastSyncedUpdatedAt => _prefs.getInt(_kLastSyncedUpdatedAt) ?? 0;
  Future<void> setLastSyncedUpdatedAt(int value) =>
      _prefs.setInt(_kLastSyncedUpdatedAt, value);

  /// Whether the user has opted in to cloud sync. Off by default — sync is
  /// optional.
  bool get enabled => _prefs.getBool(_kEnabled) ?? false;
  Future<void> setEnabled(bool value) => _prefs.setBool(_kEnabled, value);

  /// Whether there are local changes not yet confirmed uploaded. Persisted so a
  /// queued change survives an app restart while offline.
  bool get pending => _prefs.getBool(_kPending) ?? false;
  Future<void> setPending(bool value) => _prefs.setBool(_kPending, value);

  /// A stable per-install identifier, generated and cached on first use, used
  /// to tag which device produced a backup.
  String deviceId() {
    final existing = _prefs.getString(_kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random();
    final id = 'dev-'
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-'
        '${random.nextInt(1 << 32).toRadixString(16)}';
    _prefs.setString(_kDeviceId, id);
    return id;
  }
}
