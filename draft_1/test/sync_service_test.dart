import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/study_analytics.dart';
import 'package:draft_1/sync/cloud_backend.dart';
import 'package:draft_1/sync/local_store.dart';
import 'package:draft_1/sync/study_snapshot.dart';
import 'package:draft_1/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory [CloudBackend] that can simulate being offline (transport failure)
/// or rejecting requests (server error).
class FakeCloudBackend implements CloudBackend {
  RemoteDocument? stored;
  bool offline = false;
  bool reject = false;
  int uploads = 0;
  int fetches = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<RemoteDocument?> fetch() async {
    fetches++;
    if (offline) throw Exception('offline');
    if (reject) throw const CloudBackendException('rejected');
    return stored;
  }

  @override
  Future<void> upload(RemoteDocument document) async {
    uploads++;
    if (offline) throw Exception('offline');
    if (reject) throw const CloudBackendException('rejected');
    stored = document;
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late FakeCloudBackend backend;
  late StreamController<List<ConnectivityResult>> connectivity;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = FakeCloudBackend();
    connectivity = StreamController<List<ConnectivityResult>>.broadcast();

    // A known, small starting dataset.
    globals.tests = [
      Test('Math', DateTime(2026, 7, 1), TestType.quiz, TestDifficulty.easy, 80, 90),
    ];
    globals.tasksByDate = {};
    globals.decks = [Deck(name: 'General')];
    StudyAnalytics.instance.replaceSessions([]);

    SyncService.instance.resetForTest();
  });

  tearDown(() async {
    SyncService.instance.resetForTest();
    await connectivity.close();
  });

  Future<void> initWith({bool enabled = false}) async {
    if (enabled) {
      SharedPreferences.setMockInitialValues({'sync.enabled': true});
    }
    await SyncService.instance.init(
      store: await LocalStore.open(),
      backend: backend,
      connectivityStream: connectivity.stream,
    );
  }

  test('init persists seeded data locally on first launch (offline-first)',
      () async {
    await initWith();
    final store = await LocalStore.open();
    final snapshot = store.loadSnapshot();
    expect(snapshot, isNotNull);
    expect(snapshot!.tests.single.subject, 'Math');
    // Sync is off by default and nothing was uploaded.
    expect(SyncService.instance.status, SyncStatus.disabled);
    expect(backend.uploads, 0);
  });

  test('markDirty persists locally even when sync is disabled', () async {
    await initWith();
    globals.tests.add(
      Test('Bio', DateTime(2026, 8, 1), TestType.unit, TestDifficulty.normal, 50, 100),
    );
    await SyncService.instance.markDirty();

    final store = await LocalStore.open();
    expect(store.loadSnapshot()!.tests.length, 2);
    expect(store.pending, isTrue);
    expect(backend.uploads, 0);
  });

  test('enabling sync uploads local data when the cloud is empty', () async {
    await initWith();
    await SyncService.instance.setEnabled(true);

    expect(SyncService.instance.status, SyncStatus.idle);
    expect(backend.stored, isNotNull);
    expect(backend.uploads, 1);
    final uploaded = StudySnapshot.fromJson(backend.stored!.payload);
    expect(uploaded.tests.single.subject, 'Math');
    expect(SyncService.instance.hasPendingChanges, isFalse);
  });

  test('enabling sync adopts a newer cloud backup (restore across devices)',
      () async {
    // Cloud already has a backup from another device.
    final remoteSnapshot = StudySnapshot(
      tests: [
        Test('Physics', DateTime(2026, 9, 1), TestType.finals, TestDifficulty.hard, 60, 100),
      ],
      tasksByDate: {},
      decks: [Deck(name: 'Mechanics')],
      sessions: [],
    );
    backend.stored = RemoteDocument(
      payload: remoteSnapshot.toJson(),
      updatedAt: DateTime(2030).millisecondsSinceEpoch, // clearly newer
      deviceId: 'other-device',
    );

    await initWith();
    await SyncService.instance.setEnabled(true);

    // Local in-memory data was replaced with the cloud copy.
    expect(globals.tests.single.subject, 'Physics');
    expect(globals.decks.single.name, 'Mechanics');
    expect(SyncService.instance.status, SyncStatus.idle);
  });

  test('goes offline on transport failure, then auto-syncs on reconnect',
      () async {
    await initWith(enabled: true);
    // setEnabled isn't needed (already enabled); drain the init sync.
    await _settle();

    backend.offline = true;
    globals.tests.add(
      Test('Bio', DateTime(2026, 8, 1), TestType.unit, TestDifficulty.normal, 50, 100),
    );
    await SyncService.instance.markDirty();
    await SyncService.instance.syncNow();

    expect(SyncService.instance.status, SyncStatus.offline);
    expect(SyncService.instance.hasPendingChanges, isTrue);

    // Connectivity is restored.
    backend.offline = false;
    connectivity.add([ConnectivityResult.wifi]);
    await _settle();

    expect(SyncService.instance.status, SyncStatus.idle);
    expect(SyncService.instance.hasPendingChanges, isFalse);
    expect(backend.stored, isNotNull);
    expect(StudySnapshot.fromJson(backend.stored!.payload).tests.length, 2);
  });

  test('server rejection surfaces as an error status', () async {
    await initWith();
    backend.reject = true;
    await SyncService.instance.setEnabled(true);

    expect(SyncService.instance.status, SyncStatus.error);
    expect(SyncService.instance.lastError, contains('rejected'));
  });

  test('restoreFromCloud overwrites local data with the cloud copy', () async {
    final remoteSnapshot = StudySnapshot(
      tests: [],
      tasksByDate: {},
      decks: [Deck(name: 'Restored')],
      sessions: [],
    );
    backend.stored = RemoteDocument(
      payload: remoteSnapshot.toJson(),
      updatedAt: 1000,
      deviceId: 'other-device',
    );

    await initWith();
    await SyncService.instance.restoreFromCloud();

    expect(globals.decks.single.name, 'Restored');
    expect(globals.tests, isEmpty);
    final store = await LocalStore.open();
    expect(store.loadSnapshot()!.decks.single.name, 'Restored');
  });
}
