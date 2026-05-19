// Verifies the Hive-backed dedupe set in MedicationNotificationService.
//
// Background: `_notifiedMedicationIds` used to be in-memory only on a
// singleton, which evaporated under iOS process recreation. This test
// exercises the persistent layer added for fix #8 in
// docs/notifications-audit.md — write-through to a Hive box keyed by
// `notified_<yyyy-MM-dd>`, restored on init, with older buckets pruned.
//
// We avoid calling `initialize()` directly because it touches platform
// channels (flutter_local_notifications, permission_handler) that aren't
// wired up in unit tests. Instead we drive the Hive-side surface via the
// `@visibleForTesting` hooks on the service.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pinkrain/features/treatment/services/medication_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification tracking persistence', () {
    late Directory tempDir;
    late MedicationNotificationService service;

    String todayKey() => 'notified_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('test_hive_notif_tracking_');
      Hive.init(tempDir.path);
    });

    setUp(() async {
      service = MedicationNotificationService();
      // Start each test from a clean slate. resetForTesting drains pending
      // writes, clears the in-memory set, and closes the tracking box.
      await service.resetForTesting();
    });

    tearDownAll(() async {
      await service.resetForTesting();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('write-through persists entries that survive resurrection', () async {
      service.markNotifiedForTesting('treatment-A_20260519_0900');
      service.markNotifiedForTesting('treatment-B_20260519_1300');
      await service.pendingWrites;

      // Simulate the singleton being torn down and re-initialized
      // (e.g. iOS process recreation): drop the in-memory state and the
      // open box handle, then re-run the restore step.
      await service.resetForTesting();
      expect(service.notifiedMedicationIdsForTesting, isEmpty,
          reason: 'resetForTesting should drop the in-memory cache');

      // Re-seed the entries directly into Hive (since resetForTesting also
      // wiped the box, we need to re-establish persistence to prove the
      // restore reads back correctly).
      service.markNotifiedForTesting('treatment-A_20260519_0900');
      service.markNotifiedForTesting('treatment-B_20260519_1300');
      await service.pendingWrites;

      // Now simulate only the singleton resurrection: clear the in-memory
      // set without wiping Hive, then re-run restore.
      final box = await Hive.openBox('notification_tracking');
      final persisted = (box.get(todayKey()) as List).cast<String>();
      expect(persisted, containsAll(<String>['treatment-A_20260519_0900', 'treatment-B_20260519_1300']));

      // Manually evict in-memory state to simulate cold start (without
      // closing the box, since restoreTrackingForTesting reopens lazily).
      await service.pendingWrites;
      // Use the public-for-testing restore which only re-reads from Hive.
      // First, blow away in-memory by calling clearAll then awaiting writes.
      // clearAll also deletes today's bucket, so we re-seed afterwards via
      // direct Hive write to isolate the "restore only" behavior.
      service.clearAllNotificationTracking();
      await service.pendingWrites;
      await box.put(todayKey(),
          <String>['treatment-A_20260519_0900', 'treatment-B_20260519_1300']);

      await service.restoreTrackingForTesting();

      expect(service.notifiedMedicationIdsForTesting,
          containsAll(<String>['treatment-A_20260519_0900', 'treatment-B_20260519_1300']));
    });

    test('resetDailyNotifications clears the in-memory cache and Hive bucket', () async {
      service.markNotifiedForTesting('treatment-A_20260519_0900');
      await service.pendingWrites;

      final box = await Hive.openBox('notification_tracking');
      expect(box.get(todayKey()), isNotNull,
          reason: 'sanity check — entry should be persisted before reset');

      service.resetDailyNotifications();
      await service.pendingWrites;

      expect(service.notifiedMedicationIdsForTesting, isEmpty,
          reason: 'in-memory set should be cleared');
      expect(box.get(todayKey()), isNull,
          reason: 'today\'s Hive bucket should be deleted');
    });

    test('clearNotificationForMedication removes matching entries by prefix', () async {
      service.markNotifiedForTesting('treatment-A_20260519_0900');
      service.markNotifiedForTesting('treatment-A_20260519_1300');
      service.markNotifiedForTesting('treatment-B_20260519_0900');
      await service.pendingWrites;

      service.clearNotificationForMedication('treatment-A');
      await service.pendingWrites;

      expect(service.notifiedMedicationIdsForTesting, <String>{'treatment-B_20260519_0900'});

      final box = await Hive.openBox('notification_tracking');
      final persisted = (box.get(todayKey()) as List).cast<String>();
      expect(persisted, <String>['treatment-B_20260519_0900']);
    });

    test('restore does not lose live entries when a persist is pending',
        () async {
      // Regression for the race the audit re-review flagged: a notification
      // is shown (entry added in-memory, fire-and-forget persist queued); then
      // initialize() is called again in the same process (e.g. the test
      // reminder button or the data import flow both call it). Before the
      // fix, restore read the *old* Hive bucket and clobbered the live entry,
      // and the queued persist then wrote the clobbered set back to disk.
      //
      // The fix drains _pendingWrites before reading, and merges instead of
      // replacing — so the queued write lands first, the read sees the up-to-
      // date bucket, and addAll is a no-op for entries already in-memory.

      // 1. First entry: mark and fully persist.
      service.markNotifiedForTesting('treatment-A_20260520_0900');
      await service.pendingWrites;

      // 2. Second entry: mark but DO NOT await the persist. This is the race
      //    window — the in-memory set has both A and B, Hive has only A,
      //    and _pendingWrites holds the not-yet-run persist of B.
      service.markNotifiedForTesting('treatment-B_20260520_1300');

      // 3. Simulate re-init in the same session.
      await service.restoreTrackingForTesting();

      // 4. Both entries must survive in-memory.
      expect(
        service.notifiedMedicationIdsForTesting,
        containsAll(<String>[
          'treatment-A_20260520_0900',
          'treatment-B_20260520_1300',
        ]),
        reason:
            'restore must drain pending writes before reading, otherwise B is lost',
      );

      // 5. And Hive must reflect both — the drain forced B to be persisted.
      final box = await Hive.openBox('notification_tracking');
      final persisted = (box.get(todayKey()) as List).cast<String>();
      expect(
        persisted,
        containsAll(<String>[
          'treatment-A_20260520_0900',
          'treatment-B_20260520_1300',
        ]),
        reason:
            'drained persist must have landed B in Hive before restore reads',
      );
    });

    test('older date buckets are pruned on init/restore', () async {
      // Seed today plus two stale buckets directly into Hive.
      final box = await Hive.openBox('notification_tracking');
      await box.put(todayKey(), <String>['treatment-A_today']);
      await box.put('notified_2020-01-01', <String>['stale-1']);
      await box.put('notified_2024-12-31', <String>['stale-2']);
      // And a non-prefix key that must not be touched.
      await box.put('unrelated_key', 'keep-me');

      await service.restoreTrackingForTesting();

      expect(service.notifiedMedicationIdsForTesting, <String>{'treatment-A_today'});
      expect(box.get('notified_2020-01-01'), isNull);
      expect(box.get('notified_2024-12-31'), isNull);
      expect(box.get('unrelated_key'), 'keep-me',
          reason: 'prune should only touch keys with the notified_ prefix');
      expect(box.get(todayKey()), isNotNull,
          reason: 'today\'s bucket must remain after prune');
    });
  });
}
