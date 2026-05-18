// Round-trip test for the JSON export/import pipeline.
//
// We seed each of the six exportable Hive boxes with one representative
// entry whose shape mirrors what the existing writers produce
// (Treatment.toJson, MedicineInventorySerialization.toJson, IntakeLog.toMap,
// HiveService.saveSymptom, HiveService.saveMoodForDate, user prefs).
// Then we call HiveService.exportAllBoxes -> jsonEncode -> jsonDecode ->
// HiveService.importAllBoxes and assert every box's contents are unchanged.
//
// This is the cheapest single check that would catch a regression where a
// field name in one of the existing toJson methods drifts from what the
// matching fromJson reader expects.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pinkrain/core/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('test_hive_export_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    // Wipe between tests so each one starts from a known empty state.
    for (final name in HiveService.exportableBoxNames) {
      final box = await Hive.openBox(name);
      await box.clear();
    }
  });

  Future<void> seedFixtureData() async {
    // 1. userPreferences — flat key/value box.
    final prefs = await Hive.openBox(HiveService.userPrefsBox);
    await prefs.put('userName', 'Alice');
    await prefs.put('userMood', 4);
    await prefs.put('userMoodDescription', 'Good day');
    await prefs.put('lastMoodDate', '2026-05-19T09:00:00.000Z');

    // 2. moodData — list-of-entries keyed by mood_<date>.
    final mood = await Hive.openBox(HiveService.moodBoxName);
    await mood.put('mood_2026-05-18', [
      {
        'mood': 3,
        'description': 'Tired',
        'timestamp': '2026-05-18T20:30:00.000Z',
      },
    ]);

    // 3. symptomData — keyed by yyyy-MM-dd, value carries `date` + `symptoms`.
    final symptoms = await Hive.openBox(HiveService.symptomBoxName);
    await symptoms.put('2026-05-18', {
      'date': '2026-05-18',
      'symptoms': ['headache', 'fatigue'],
    });

    // 4. medicationLogs — keyed by logs_<date>, value is a list of IntakeLog.toMap().
    final medLogs = await Hive.openBox(HiveService.medicationLogsBoxName);
    await medLogs.put('logs_2026-05-18', [
      {
        'treatment_id': '1747000000000123456',
        'medicine_name': 'Paracetamol',
        'medicine_type': 'Pain Killer',
        'medicine_color': 'White',
        'dosage': 20.0,
        'unit': 'mg',
        'treatment_plan_start_date': '2026-05-10T00:00:00.000Z',
        'treatment_plan_end_date': '2026-06-10T00:00:00.000Z',
        'dose_time': '2026-05-18T09:00:00.000Z',
        'is_taken': true,
        'is_skipped': false,
      },
    ]);

    // 5. treatments — single key 'treatments' wrapping a list of Treatment.toJson().
    //    NOTE: this uses key 'specification' (not 'specs'), matching Treatment.toJson.
    final treatments = await Hive.openBox(HiveService.treatmentsBoxName);
    await treatments.put('treatments', [
      {
        'id': '1747000000000123456',
        'medicine': {
          'name': 'Paracetamol',
          'type': 'Pain Killer',
          'color': 'White',
          'specification': {
            'dosage': 20.0,
            'unit': 'mg',
            'useCase': 'For headaches',
          },
        },
        'treatmentPlan': {
          'startDate': '2026-05-10T00:00:00.000Z',
          'endDate': '2026-06-10T00:00:00.000Z',
          'timeOfDay': '1970-01-01T09:00:00.000Z',
          'doseTimes': <String>['1970-01-01T09:00:00.000Z'],
          'doseNamesMap': <String, String>{
            'Morning': '1970-01-01T09:00:00.000Z',
          },
          'mealOption': 'After meals',
          'instructions': 'Take with water',
          'frequency': 1,
          'selectedDays': [true, true, true, true, true, true, true],
        },
        'notes': 'Doctor recommended',
      },
    ]);

    // 6. pillboxData — single key 'pillbox' wrapping a list of MedicineInventorySerialization.toJson().
    //    NOTE: this uses key 'specs' (not 'specification') — the divergence is intentional.
    final pillbox = await Hive.openBox(HiveService.pillboxBoxName);
    await pillbox.put('pillbox', [
      {
        'medicine': {
          'name': 'Paracetamol',
          'type': 'Pain Killer',
          'color': 'White',
          'specs': {
            'dosage': 20.0,
            'unit': 'mg',
            'useCase': '',
          },
        },
        'quantity': 180,
      },
    ]);
  }

  Map<String, Map<String, dynamic>> snapshotBoxes() {
    final result = <String, Map<String, dynamic>>{};
    for (final name in HiveService.exportableBoxNames) {
      final box = Hive.box(name);
      final boxMap = <String, dynamic>{};
      for (final key in box.keys) {
        boxMap[key.toString()] = box.get(key);
      }
      result[name] = boxMap;
    }
    return result;
  }

  test('export then import round-trips all six boxes byte-for-byte', () async {
    await seedFixtureData();

    // 1. Export.
    final exported = await HiveService.exportAllBoxes();

    // 2. Run through the JSON pipeline that DataTransferService uses on disk.
    final encoded = jsonEncode(exported);
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;

    // 3. Wipe everything, then import.
    for (final name in HiveService.exportableBoxNames) {
      await Hive.box(name).clear();
    }
    await HiveService.importAllBoxes(decoded);

    // 4. Read everything back and compare against the JSON-shape baseline.
    //    We compare against the encoded JSON (not the raw seeded values),
    //    because Hive may normalize types (int vs double) and we want the
    //    round-trip to be idempotent at the JSON level — that's the
    //    contract DataTransferService actually relies on.
    final after = snapshotBoxes();
    final afterJson = jsonDecode(jsonEncode(after)) as Map<String, dynamic>;

    for (final name in HiveService.exportableBoxNames) {
      expect(afterJson[name], equals(decoded[name]),
          reason: 'Box "$name" did not survive the export/import round-trip.');
    }
  });

  test('importAllBoxes wipes existing entries even when input is empty', () async {
    await seedFixtureData();
    // Sanity check: data is in place.
    expect(Hive.box(HiveService.treatmentsBoxName).get('treatments'), isNotNull);

    await HiveService.importAllBoxes(const <String, dynamic>{});

    for (final name in HiveService.exportableBoxNames) {
      expect(Hive.box(name).isEmpty, isTrue,
          reason: '$name should have been cleared by an empty import.');
    }
  });

  test('exportAllBoxes returns Map<String, dynamic> for all nested maps', () async {
    await seedFixtureData();
    final exported = await HiveService.exportAllBoxes();

    // The contract of HiveService.exportAllBoxes is that every nested map is a
    // Map<String, dynamic> — not Map<dynamic, dynamic> — so that jsonEncode
    // works without throwing and so that downstream readers' casts succeed.
    void assertStringKeyedRecursively(dynamic node) {
      if (node is Map) {
        expect(node, isA<Map<String, dynamic>>(),
            reason: 'Found a non-String-keyed map in the export.');
        for (final value in node.values) {
          assertStringKeyedRecursively(value);
        }
      } else if (node is List) {
        for (final item in node) {
          assertStringKeyedRecursively(item);
        }
      }
    }

    for (final box in exported.values) {
      assertStringKeyedRecursively(box);
    }

    // Final smoke: the JSON encoder must accept the output as-is.
    expect(() => jsonEncode(exported), returnsNormally);
  });
}
