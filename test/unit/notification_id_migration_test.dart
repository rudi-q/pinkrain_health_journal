// Regression tests for the ID-scheme migration in MedicationSchedulerService.
//
// Background: the migration used to wholesale clear `scheduled_notifications`,
// relying on `_restoreScheduledNotifications`'s fallback rebuild to repopulate
// from current treatments. That rebuild filters by `TreatmentPlan.isOnGoing()`,
// which is stricter than the scheduler's own date-bounds logic — so legitimate
// future reminders (e.g. for a treatment whose endDate just passed midnight
// but with later same-day doses still owed) would silently disappear after a
// scheme bump. The fix is to preserve every record and only rewrite its `id`.
//
// We avoid calling `MedicationSchedulerService.initialize()` directly because
// it touches `flutter_local_notifications` platform channels not wired up in
// unit tests. Instead we drive `_migrateIdSchemeIfNeeded` via the
// `@visibleForTesting` hook on the service. The migration internally calls
// `_notificationService.cancelAllNotifications()`, which throws a
// MissingPluginException under the test runner — that's caught inside the
// migration's inner try/catch, so the record-rewriting half of the migration
// still runs and is what these tests exercise.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pinkrain/features/treatment/services/medication_scheduler_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification ID-scheme migration', () {
    late Directory tempDir;
    const String boxName = 'medication_scheduler';
    const String scheduledKey = 'scheduled_notifications';
    const String versionKey = 'id_scheme_version';

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('test_hive_id_migration_');
      Hive.init(tempDir.path);
    });

    setUp(() async {
      // Start each test from a clean box state. The singleton itself holds no
      // in-memory state we need to reset — all migration data lives in Hive.
      final box = await Hive.openBox(boxName);
      await box.clear();
    });

    tearDownAll(() async {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('preserves records and rewrites each id with the new scheme', () async {
      // Seed pre-migration state: records with arbitrary old `id` values
      // (representing what String.hashCode-derived IDs might have looked like)
      // and NO `id_scheme_version` key.
      final box = await Hive.openBox(boxName);
      final oldRecords = <Map<String, dynamic>>[
        {
          'id': 12345,
          'medicationId': 'treat_A_20260520_0900',
          'scheduledTime': 1748422800000,
          'type': 'main',
        },
        {
          'id': 67890,
          'medicationId': 'treat_B_20260520_1300',
          'scheduledTime': 1748437200000,
          'type': 'main',
        },
      ];
      await box.put(scheduledKey, oldRecords);

      await MedicationSchedulerService().migrateIdSchemeForTesting();

      // Records must still be present, NOT wiped — this is the whole point.
      final migratedRaw = box.get(scheduledKey) as List;
      expect(migratedRaw.length, equals(oldRecords.length),
          reason: 'migration must preserve, not drop, valid records');

      for (var i = 0; i < migratedRaw.length; i++) {
        final record = Map<String, dynamic>.from(migratedRaw[i] as Map);
        final expectedNewId = MedicationSchedulerService.stableNotificationId(
          record['medicationId'] as String,
          record['scheduledTime'] as int,
        );
        expect(record['id'], equals(expectedNewId),
            reason: 'each id must be rewritten with the new FNV-1a scheme');
        expect(record['medicationId'], equals(oldRecords[i]['medicationId']),
            reason: 'medicationId must be preserved verbatim');
        expect(record['scheduledTime'], equals(oldRecords[i]['scheduledTime']),
            reason: 'scheduledTime must be preserved verbatim');
        expect(record['type'], equals(oldRecords[i]['type']));
        // Sanity: the rewritten id is NOT the same as the old hashCode-derived id.
        expect(record['id'], isNot(equals(oldRecords[i]['id'])),
            reason: 'old id should have been replaced (test fixture used a value '
                'that cannot coincide with FNV-1a output for this input)');
      }

      expect(box.get(versionKey), equals(2),
          reason: 'version stamp must be set to current after migration');
    });

    test('is a no-op once the version stamp is current', () async {
      final box = await Hive.openBox(boxName);
      final records = <Map<String, dynamic>>[
        {
          'id': 999,
          'medicationId': 'treat_X_20260520_0900',
          'scheduledTime': 1748422800000,
          'type': 'main',
        },
      ];
      await box.put(scheduledKey, records);
      await box.put(versionKey, 2);

      await MedicationSchedulerService().migrateIdSchemeForTesting();

      final after = box.get(scheduledKey) as List;
      expect(after.length, 1);
      // The id field is left exactly as it was — no rewriting on a current box.
      expect((after[0] as Map)['id'], equals(999),
          reason: 'migration must not touch records when version is already current');
    });

    test('drops malformed records but preserves valid ones', () async {
      final box = await Hive.openBox(boxName);
      await box.put(scheduledKey, <Map<String, dynamic>>[
        // empty medicationId — can't rebuild
        {'id': 1, 'medicationId': '', 'scheduledTime': 1000, 'type': 'main'},
        // null scheduledTime — can't compute new id
        {'id': 2, 'medicationId': 'x', 'scheduledTime': null, 'type': 'main'},
        // valid
        {'id': 3, 'medicationId': 'y_z', 'scheduledTime': 1748422800000, 'type': 'main'},
      ]);

      await MedicationSchedulerService().migrateIdSchemeForTesting();

      final after = (box.get(scheduledKey) as List).cast<Map>();
      expect(after.length, 1,
          reason: 'only the malformed records should be dropped');
      expect(after[0]['medicationId'], 'y_z');
      expect(after[0]['scheduledTime'], 1748422800000);
    });

    test('preserves records even when cancelAllNotifications throws', () async {
      // The migration tries to cancel OS-level notifications first; in the
      // unit-test environment that call throws (no plugin). The migration
      // must still rewrite the persisted records so the next launch's restore
      // can re-arm them. (This test implicitly exercises that path because
      // the plugin is unavailable in every test in this group; the assertion
      // is that records survive the throw.)
      final box = await Hive.openBox(boxName);
      await box.put(scheduledKey, <Map<String, dynamic>>[
        {
          'id': 42,
          'medicationId': 'treat_C_20260520_2000',
          'scheduledTime': 1748469600000,
          'type': 'main',
        },
      ]);

      await MedicationSchedulerService().migrateIdSchemeForTesting();

      final after = (box.get(scheduledKey) as List).cast<Map>();
      expect(after.length, 1);
      expect(after[0]['medicationId'], 'treat_C_20260520_2000');
      expect(box.get(versionKey), 2,
          reason: 'version stamp lands even if cancellation throws');
    });
  });
}
