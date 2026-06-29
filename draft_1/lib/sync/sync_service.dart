import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'cloud_backend.dart';
import 'local_store.dart';
import 'study_snapshot.dart';
import 'sync_config.dart';

/// High-level state of the sync engine, surfaced to the settings UI.
enum SyncStatus {
  /// No backend configured, or the user has not opted in.
  disabled,

  /// Idle and up to date (or never synced yet).
  idle,

  /// A sync is in flight.
  syncing,

  /// Last attempt failed because the device looks offline; will retry when
  /// connectivity returns.
  offline,

  /// Last attempt was refused by the server (auth/server error).
  error,
}

/// Owns offline-first persistence of the user's study data and, when enabled,
/// keeps it backed up to the cloud and restorable across devices.
///
/// Design:
///   * **Offline-first** — every change is written to local storage
///     immediately (via [markDirty]); the app never depends on the network to
///     function. The local copy is loaded into the in-memory stores on
///     [init], before the first frame.
///   * **Optional** — cloud sync only runs when the user enables it *and* a
///     backend is configured. Otherwise the app is a normal offline app.
///   * **Automatic on reconnect** — a [Connectivity] subscription flushes any
///     pending local changes as soon as connectivity is restored.
///
/// Conflicts (both the local and cloud copies changed since they last agreed)
/// are resolved by [StudySnapshot.merge], a non-destructive union.
class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  late LocalStore _store;
  late CloudBackend _backend;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _debounce;

  bool _initialised = false;
  bool _syncing = false;
  bool _resyncRequested = false;

  SyncStatus _status = SyncStatus.disabled;
  SyncStatus get status => _status;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  String? _lastError;
  String? get lastError => _lastError;

  bool get isConfigured => _backend.isConfigured;
  bool get enabled => _initialised && _store.enabled;
  bool get hasPendingChanges => _initialised && _store.pending;

  /// How long to wait after the last edit before pushing, so a burst of edits
  /// (e.g. saving several flashcards) coalesces into one upload.
  static const _debounceDelay = Duration(seconds: 2);

  /// Loads the locally-persisted data into memory and wires up sync. Safe to
  /// call once, before `runApp`. Test seams: pass [store]/[backend] to inject
  /// fakes and [connectivityStream] to drive reconnect behaviour.
  Future<void> init({
    LocalStore? store,
    CloudBackend? backend,
    Stream<List<ConnectivityResult>>? connectivityStream,
  }) async {
    if (_initialised) return;
    _store = store ?? await LocalStore.open();
    _backend = backend ?? SyncConfig.fromEnvironment().buildBackend();
    _initialised = true;

    final local = _store.loadSnapshot();
    if (local != null) {
      // Restore the user's data so the very first frame shows it (offline).
      local.restore();
    } else {
      // First launch: persist whatever the app seeded so it survives restarts.
      await _store.saveSnapshot(StudySnapshot.capture());
    }

    _recomputeIdleStatus();
    notifyListeners();

    _connectivitySub = (connectivityStream ??
            Connectivity().onConnectivityChanged)
        .listen(_onConnectivityChanged);

    // Reconcile with the cloud in the background; never block startup on it.
    if (enabled && isConfigured) {
      unawaited(syncNow());
    }
  }

  /// Records that the in-memory study data changed: snapshots it to local
  /// storage right away (so it is safe across restarts and offline), marks it
  /// pending upload, and schedules a debounced cloud push.
  Future<void> markDirty() async {
    if (!_initialised) return;
    final snapshot = StudySnapshot.capture();
    await _store.saveSnapshot(snapshot);
    await _store.setLocalUpdatedAt(DateTime.now().millisecondsSinceEpoch);
    await _store.setPending(true);
    notifyListeners();

    if (enabled && isConfigured) {
      _debounce?.cancel();
      _debounce = Timer(_debounceDelay, () => unawaited(syncNow()));
    }
  }

  /// Turns cloud sync on or off. Enabling triggers an immediate reconcile so an
  /// existing backup is pulled (and the local data pushed).
  Future<void> setEnabled(bool value) async {
    if (!_initialised) return;
    await _store.setEnabled(value);
    if (value && isConfigured) {
      await syncNow(manual: true);
    } else {
      _recomputeIdleStatus();
      notifyListeners();
    }
  }

  /// Reconciles local and cloud copies. [manual] marks a user-initiated sync so
  /// it runs even outside the debounce. Overlapping calls coalesce: a request
  /// made while a sync is running schedules exactly one follow-up.
  Future<void> syncNow({bool manual = false}) async {
    if (!_initialised || !enabled || !isConfigured) {
      _recomputeIdleStatus();
      notifyListeners();
      return;
    }
    if (_syncing) {
      _resyncRequested = true;
      return;
    }
    _syncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      await _reconcile();
      _lastSyncedAt = DateTime.now();
      _lastError = null;
      _setStatus(SyncStatus.idle);
    } on CloudBackendException catch (e) {
      // Server reachable but refused — surface as an error, keep data pending.
      _lastError = e.message;
      _setStatus(SyncStatus.error);
    } catch (e) {
      // Transport failure → treat as offline; the connectivity listener and the
      // next edit will retry. Keep the change pending.
      _lastError = e.toString();
      _setStatus(SyncStatus.offline);
    } finally {
      _syncing = false;
      if (_resyncRequested) {
        _resyncRequested = false;
        unawaited(syncNow());
      }
    }
  }

  /// Pulls the cloud copy and overwrites local data with it, discarding
  /// unsynced local changes. Exposed for an explicit "restore from backup"
  /// action in the UI.
  Future<void> restoreFromCloud() async {
    if (!_initialised || !isConfigured) return;
    _syncing = true;
    _setStatus(SyncStatus.syncing);
    try {
      final remote = await _backend.fetch();
      if (remote != null) {
        await _adoptRemote(remote);
      }
      _lastSyncedAt = DateTime.now();
      _lastError = null;
      _setStatus(SyncStatus.idle);
    } on CloudBackendException catch (e) {
      _lastError = e.message;
      _setStatus(SyncStatus.error);
    } catch (e) {
      _lastError = e.toString();
      _setStatus(SyncStatus.offline);
    } finally {
      _syncing = false;
    }
  }

  // --- Internals ------------------------------------------------------------

  Future<void> _reconcile() async {
    final remote = await _backend.fetch();
    final localSnapshot = _store.loadSnapshot() ?? StudySnapshot.capture();
    final localUpdatedAt = _store.localUpdatedAt;
    final lastSynced = _store.lastSyncedUpdatedAt;
    final hasLocalChanges = _store.pending;

    // No backup exists yet → push whatever we have.
    if (remote == null) {
      await _push(localSnapshot, localUpdatedAt);
      return;
    }

    final remoteIsNew = remote.updatedAt > lastSynced;

    if (hasLocalChanges && remoteIsNew) {
      // Both sides advanced since they last agreed → non-destructive merge,
      // then push the merged result so every device converges on it.
      final merged = StudySnapshot.merge(localSnapshot,
          StudySnapshot.fromJson(remote.payload));
      final mergedAt = DateTime.now().millisecondsSinceEpoch;
      merged.restore();
      await _store.saveSnapshot(merged);
      await _push(merged, mergedAt);
      return;
    }

    if (remoteIsNew) {
      // Cloud has newer data and we have nothing pending → adopt it.
      await _adoptRemote(remote);
      return;
    }

    if (hasLocalChanges) {
      // Only local advanced → push it.
      await _push(localSnapshot, localUpdatedAt);
    }
    // Otherwise already in sync; nothing to do.
  }

  Future<void> _push(StudySnapshot snapshot, int updatedAt) async {
    await _backend.upload(RemoteDocument(
      payload: snapshot.toJson(),
      updatedAt: updatedAt,
      deviceId: _store.deviceId(),
    ));
    await _store.setLastSyncedUpdatedAt(updatedAt);
    await _store.setLocalUpdatedAt(updatedAt);
    await _store.setPending(false);
  }

  Future<void> _adoptRemote(RemoteDocument remote) async {
    final snapshot = StudySnapshot.fromJson(remote.payload);
    snapshot.restore();
    await _store.saveSnapshot(snapshot);
    await _store.setLocalUpdatedAt(remote.updatedAt);
    await _store.setLastSyncedUpdatedAt(remote.updatedAt);
    await _store.setPending(false);
    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online =
        results.any((r) => r != ConnectivityResult.none) && results.isNotEmpty;
    if (online && enabled && isConfigured && _store.pending) {
      unawaited(syncNow());
    }
  }

  void _recomputeIdleStatus() {
    _status = (enabled && isConfigured) ? SyncStatus.idle : SyncStatus.disabled;
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Tears the singleton back down to a pristine state so each test can call
  /// [init] again with fresh fakes.
  @visibleForTesting
  void resetForTest() {
    _debounce?.cancel();
    _connectivitySub?.cancel();
    _debounce = null;
    _connectivitySub = null;
    _initialised = false;
    _syncing = false;
    _resyncRequested = false;
    _status = SyncStatus.disabled;
    _lastSyncedAt = null;
    _lastError = null;
  }
}
