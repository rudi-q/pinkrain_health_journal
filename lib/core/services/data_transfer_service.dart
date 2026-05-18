import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/data/journal_log.dart';
import 'package:pinkrain/features/treatment/services/medication_notification_service.dart';
import 'package:pinkrain/features/treatment/services/medication_scheduler_service.dart';

/// Serializes all user data to a single JSON file and restores it on import.
///
/// Exported boxes are the six in [HiveService.exportableBoxNames]. Device-
/// specific boxes (`medication_scheduler`, `medication_actions`) and
/// `disclaimer_box` are intentionally excluded; the scheduler is cleared and
/// rebuilt from the imported treatments at the end of [importFromFile].
class DataTransferService {
  DataTransferService._();

  static const String schemaTag = 'pinkrain-export';
  static const int schemaVersion = 1;

  // Hive box of per-medication status (snooze timestamps etc.) — wiped on
  // import because the timestamps are bound to the previous device's clock.
  // The scheduler box (`medication_scheduler`) is cleared transitively by
  // MedicationSchedulerService.cancelAllNotifications().
  static const String _actionsBoxName = 'medication_actions';

  /// Write the export JSON to a temporary file and return its path.
  /// The caller is responsible for sharing/saving the file.
  static Future<String> exportToFile() async {
    final boxes = await HiveService.exportAllBoxes();
    String appVersion = '';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // Non-fatal: the version label is informational only.
    }

    final envelope = <String, dynamic>{
      'schema': schemaTag,
      'version': schemaVersion,
      'appVersion': appVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'boxes': boxes,
    };

    final payload = jsonEncode(envelope);
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/pinkrain_export_$stamp.json');
    await file.writeAsString(payload);
    devPrint('📤 Wrote export (${payload.length} bytes) to ${file.path}');
    return file.path;
  }

  /// Read, validate, and apply an export file. Replaces all user data on
  /// success. Throws [DataImportException] with a user-facing message on any
  /// validation or I/O error.
  static Future<void> importFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const DataImportException('Selected file does not exist.');
    }

    final String raw;
    try {
      raw = await file.readAsString();
    } catch (e) {
      throw DataImportException('Could not read the file: $e');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const DataImportException(
          'File is not valid JSON. Please choose a PinkRain export file.');
    }

    final boxes = validateEnvelope(decoded);

    // 1. Cancel any scheduled system notifications before we wipe the
    //    scheduler box (this also clears that box via resetScheduledNotifications).
    try {
      await MedicationSchedulerService().cancelAllNotifications();
    } catch (e) {
      devPrint('⚠️ cancelAllNotifications failed during import: $e');
      // Continue — stale notifications are a nuisance, not a blocker.
    }

    // 2. Clear the action-status box (snooze timestamps are tied to the old device).
    try {
      final actionsBox = await Hive.openBox(_actionsBoxName);
      await actionsBox.clear();
    } catch (e) {
      devPrint('⚠️ Could not clear $_actionsBoxName: $e');
    }

    // 3. Replace user-data boxes. This is the only step that mutates the
    //    user-visible state; everything before is cleanup, everything after
    //    is re-derivation.
    await HiveService.importAllBoxes(boxes);

    // 4. Re-schedule notifications from the freshly imported treatments,
    //    mirroring the startup flow in main.dart.
    try {
      final notificationService = MedicationNotificationService();
      await notificationService.initialize();
      notificationService.clearAllNotificationTracking();

      final journalLog = JournalLog();
      final today = DateTime.now().normalize();
      final todayMeds =
          await journalLog.getMedicationsForTheDay(today, forceReload: true);
      final untaken =
          todayMeds.where((m) => !m.isTaken && !m.isSkipped).toList();

      await notificationService.showUntakenMedicationNotifications(
        untaken,
        forceReschedule: true,
        showImmediateNotifications: false,
      );
    } catch (e) {
      devPrint('⚠️ Re-scheduling notifications after import failed: $e');
      // Data is already imported — surface a warning but don't roll back.
    }

    devPrint('✅ Import complete');
  }

  /// Validate a parsed export envelope without touching any state. Returns
  /// the validated `boxes` map. Throws [DataImportException] on the same
  /// conditions [importFromFile] would. Lifted out so the destructive path
  /// in [importFromFile] runs only after this returns cleanly.
  static Map<String, dynamic> validateEnvelope(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw const DataImportException(
          'Unexpected file format. Please choose a PinkRain export file.');
    }

    if (decoded['schema'] != schemaTag) {
      throw const DataImportException(
          'This does not look like a PinkRain export file.');
    }

    final fileVersion = decoded['version'];
    if (fileVersion != schemaVersion) {
      throw DataImportException(
          'Unsupported export version ($fileVersion). This app expects version $schemaVersion.');
    }

    final boxes = decoded['boxes'];
    if (boxes is! Map<String, dynamic>) {
      throw const DataImportException(
          'Export file is missing the "boxes" section.');
    }

    _spotCheckShapes(boxes);
    return boxes;
  }

  /// Reject malformed exports up-front so we never enter the wipe path on
  /// bad input.
  ///
  ///   - every box in [HiveService.exportableBoxNames] must be present and
  ///     a Map (possibly empty). `HiveService.exportAllBoxes` always writes
  ///     all six wrappers, so a missing key means the file was truncated or
  ///     hand-edited — and accepting it would let
  ///     `HiveService.importAllBoxes` clear the local box and skip
  ///     repopulation, silently destroying user data;
  ///   - every payload shape that a downstream reader will eventually cast
  ///     is type-checked here. The principle is: since import is destructive,
  ///     no badly-typed value gets past validation. Readers fall into two
  ///     groups — the strict ones (`Treatment.fromJson`,
  ///     `getUserMood`/`getUserName`, the `as int`/`as String` casts in
  ///     `wellness_screen.dart`) crash on a wrong type, which would hit the
  ///     user the instant they land on /wellness after import; the defensive
  ///     ones (`IntakeLog.fromMap`) silently substitute placeholders, which
  ///     is even worse because the user can't tell their data is gone.
  static void _spotCheckShapes(Map<String, dynamic> boxes) {
    // 1. Every exportable box must be present and a Map.
    for (final boxName in HiveService.exportableBoxNames) {
      if (!boxes.containsKey(boxName)) {
        throw DataImportException(
            'Export file is missing the "$boxName" box. It may be truncated or corrupted.');
      }
      if (boxes[boxName] is! Map) {
        throw DataImportException(
            'Box "$boxName" must be a map (got ${boxes[boxName].runtimeType}).');
      }
    }

    _validateUserPreferences(boxes[HiveService.userPrefsBox] as Map);
    _validateMoodData(boxes[HiveService.moodBoxName] as Map);
    _validateSymptomData(boxes[HiveService.symptomBoxName] as Map);
    _validateMedicationLogs(boxes[HiveService.medicationLogsBoxName] as Map);

    final treatmentsBox = boxes[HiveService.treatmentsBoxName] as Map;
    final treatmentsList = treatmentsBox['treatments'];
    if (treatmentsList != null && treatmentsList is! List) {
      throw const DataImportException(
          'Export file is malformed: "treatments" should be a list.');
    }
    if (treatmentsList is List) {
      for (var i = 0; i < treatmentsList.length; i++) {
        _validateTreatmentEntry(treatmentsList[i], i);
      }
    }

    final pillboxBox = boxes[HiveService.pillboxBoxName] as Map;
    final pillboxList = pillboxBox['pillbox'];
    if (pillboxList != null && pillboxList is! List) {
      throw const DataImportException(
          'Export file is malformed: "pillbox" should be a list.');
    }
    if (pillboxList is List) {
      for (var i = 0; i < pillboxList.length; i++) {
        _validatePillboxEntry(pillboxList[i], i);
      }
    }
  }

  /// `getUserMood` / `getUserName` etc. have `Future<int>` / `Future<String>`
  /// return types — a wrong-typed value in Hive triggers a TypeError on
  /// the implicit cast at the await boundary. Strict on the four known
  /// keys; unknown keys are accepted (forward compat).
  static void _validateUserPreferences(Map box) {
    for (final entry in box.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      switch (key) {
        case 'userMood':
          if (value is! int) {
            throw DataImportException(
                '"userPreferences.userMood" must be an integer (got ${value.runtimeType}).');
          }
          break;
        case 'userName':
        case 'userMoodDescription':
        case 'lastMoodDate':
          if (value is! String) {
            throw DataImportException(
                '"userPreferences.$key" must be a string (got ${value.runtimeType}).');
          }
          break;
      }
    }
  }

  /// `wellness_screen.dart:201` casts mood as int. `getMoodEntriesForDate`
  /// handles two value shapes for back-compat: a single Map (legacy) or a
  /// List of Maps. We accept both, and inside each entry validate the three
  /// fields that downstream code reads.
  static void _validateMoodData(Map box) {
    for (final entry in box.entries) {
      final key = entry.key;
      final value = entry.value;
      final label = key is String ? key : key.toString();
      if (value is Map) {
        _validateMoodEntry(value, label, 0);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is! Map) {
            throw DataImportException(
                'moodData["$label"][$i] must be a map (got ${value[i].runtimeType}).');
          }
          _validateMoodEntry(value[i] as Map, label, i);
        }
      } else {
        throw DataImportException(
            'moodData["$label"] must be a list or map (got ${value.runtimeType}).');
      }
    }
  }

  static void _validateMoodEntry(Map entry, String key, int index) {
    final location = 'moodData["$key"][$index]';
    final mood = entry['mood'];
    if (mood is! int) {
      throw DataImportException(
          '"mood" in $location must be an integer (got ${mood.runtimeType}).');
    }
    _requireString(entry['description'], 'description', location);
    _requireDateString(entry['timestamp'], 'timestamp', location);
  }

  /// `getSymptomEntries` does `List<String>.from(entry['symptoms'])` and
  /// `DateTime.parse(entry['date'])`. Both throw on type mismatch.
  static void _validateSymptomData(Map box) {
    for (final entry in box.entries) {
      final key = entry.key;
      final value = entry.value;
      final label = key is String ? key : key.toString();
      if (value is! Map) {
        throw DataImportException(
            'symptomData["$label"] must be a map (got ${value.runtimeType}).');
      }
      // `getSymptomEntries` does `DateTime.parse(entry['date'])` inside a
      // loop wrapped in `try/catch` that returns `[]` — so a single
      // unparseable date silently drops ALL symptom data forever, not just
      // the bad entry. Validate parseability, not just string-ness.
      _requireDateString(value['date'], 'date', 'symptomData["$label"]');
      final symptoms = value['symptoms'];
      if (symptoms is! List) {
        throw DataImportException(
            '"symptoms" in symptomData["$label"] must be a list (got ${symptoms.runtimeType}).');
      }
      for (var i = 0; i < symptoms.length; i++) {
        if (symptoms[i] is! String) {
          throw DataImportException(
              '"symptoms[$i]" in symptomData["$label"] must be a string (got ${symptoms[i].runtimeType}).');
        }
      }
    }
  }

  /// `IntakeLog.fromMap` is intentionally defensive about per-field types,
  /// silently substituting "Unknown Medicine" / `0.0` dosage / `false` /
  /// `DateTime.now()` for missing or wrong-typed fields. That defensiveness
  /// is exactly the silent-corruption mode we cannot accept here: a
  /// hand-edited export with `dosage: "ten"` would import without error and
  /// then quietly become `dosage: 1.0` in the user's history. So we
  /// validate every field `IntakeLog.toMap` writes, strictly to the type
  /// the writer produces. `dose_time` is the only field allowed to be null
  /// or missing (it's optional for legacy single-dose treatments).
  static void _validateMedicationLogs(Map box) {
    for (final entry in box.entries) {
      final key = entry.key;
      final value = entry.value;
      final label = key is String ? key : key.toString();
      if (value is! List) {
        throw DataImportException(
            'medicationLogs["$label"] must be a list (got ${value.runtimeType}).');
      }
      for (var i = 0; i < value.length; i++) {
        if (value[i] is! Map) {
          throw DataImportException(
              'medicationLogs["$label"][$i] must be a map (got ${value[i].runtimeType}).');
        }
        _validateMedicationLogEntry(value[i] as Map, label, i);
      }
    }
  }

  static void _validateMedicationLogEntry(Map row, String key, int index) {
    final location = 'medicationLogs["$key"][$index]';
    _requireString(row['treatment_id'], 'treatment_id', location);
    _requireString(row['medicine_name'], 'medicine_name', location);
    _requireString(row['medicine_type'], 'medicine_type', location);
    _requireString(row['medicine_color'], 'medicine_color', location);
    _requireNum(row['dosage'], 'dosage', location);
    _requireString(row['unit'], 'unit', location);
    _requireDateString(row['treatment_plan_start_date'],
        'treatment_plan_start_date', location);
    _requireDateString(row['treatment_plan_end_date'],
        'treatment_plan_end_date', location);
    _requireBool(row['is_taken'], 'is_taken', location);
    _requireBool(row['is_skipped'], 'is_skipped', location);

    // dose_time is the one optional field: null/missing is legitimate
    // (single-dose treatments from older app versions). If present, must
    // be a parseable ISO-8601 string.
    final doseTime = row['dose_time'];
    if (doseTime != null) {
      _requireDateString(doseTime, 'dose_time', location);
    }
  }

  /// Mirrors every cast/parse in `Treatment.fromJson`
  /// (lib/features/treatment/domain/treatment_manager.dart:67-150).
  static void _validateTreatmentEntry(dynamic entry, int index) {
    if (entry is! Map) {
      throw DataImportException(
          'Treatment #${index + 1} is not an object.');
    }
    final medicine = entry['medicine'];
    final plan = entry['treatmentPlan'];
    if (medicine is! Map) {
      throw DataImportException(
          'Treatment #${index + 1} is missing "medicine".');
    }
    if (plan is! Map) {
      throw DataImportException(
          'Treatment #${index + 1} is missing "treatmentPlan".');
    }

    _requireString(medicine['name'], 'medicine.name', 'treatment #${index + 1}');
    _requireString(medicine['type'], 'medicine.type', 'treatment #${index + 1}');
    _requireString(medicine['color'], 'medicine.color', 'treatment #${index + 1}');

    final spec = medicine['specification'];
    if (spec is! Map) {
      throw DataImportException(
          'Treatment #${index + 1} is missing "medicine.specification".');
    }
    _requireNum(spec['dosage'], 'medicine.specification.dosage',
        'treatment #${index + 1}');
    _requireString(
        spec['unit'], 'medicine.specification.unit', 'treatment #${index + 1}');
    _requireString(spec['useCase'], 'medicine.specification.useCase',
        'treatment #${index + 1}');

    _requireDateString(plan['startDate'], 'treatmentPlan.startDate',
        'treatment #${index + 1}');
    _requireDateString(
        plan['endDate'], 'treatmentPlan.endDate', 'treatment #${index + 1}');
    _requireDateString(plan['timeOfDay'], 'treatmentPlan.timeOfDay',
        'treatment #${index + 1}');
    _requireString(plan['mealOption'], 'treatmentPlan.mealOption',
        'treatment #${index + 1}');
    _requireString(plan['instructions'], 'treatmentPlan.instructions',
        'treatment #${index + 1}');
    _requireInt(plan['frequency'], 'treatmentPlan.frequency',
        'treatment #${index + 1}');

    _requireString(entry['notes'], 'notes', 'treatment #${index + 1}');

    // Optional fields. Treatment.fromJson tolerates them being absent, but
    // if present each one is cast/parsed and would crash → "Error Treatment"
    // fallback. Validate everything that's actually there.
    final doseTimes = plan['doseTimes'];
    if (doseTimes != null) {
      if (doseTimes is! List) {
        throw DataImportException(
            '"treatmentPlan.doseTimes" in treatment #${index + 1} must be a list (got ${doseTimes.runtimeType}).');
      }
      for (var j = 0; j < doseTimes.length; j++) {
        _requireDateString(doseTimes[j], 'treatmentPlan.doseTimes[$j]',
            'treatment #${index + 1}');
      }
    }

    final doseNamesMap = plan['doseNamesMap'];
    if (doseNamesMap != null) {
      if (doseNamesMap is! Map) {
        throw DataImportException(
            '"treatmentPlan.doseNamesMap" in treatment #${index + 1} must be a map (got ${doseNamesMap.runtimeType}).');
      }
      doseNamesMap.forEach((name, time) {
        if (name is! String) {
          throw DataImportException(
              '"treatmentPlan.doseNamesMap" in treatment #${index + 1} has a non-string key.');
        }
        _requireDateString(time, 'treatmentPlan.doseNamesMap["$name"]',
            'treatment #${index + 1}');
      });
    }

    final selectedDays = plan['selectedDays'];
    if (selectedDays != null) {
      if (selectedDays is! List) {
        throw DataImportException(
            '"treatmentPlan.selectedDays" in treatment #${index + 1} must be a list (got ${selectedDays.runtimeType}).');
      }
      // Must be exactly 7 — TreatmentPlan.shouldTakeOnDate indexes by
      // weekday 0..6 (treatment.dart:82). A shorter list throws RangeError
      // the next time the journal computes today's doses, after the import
      // dialog has already closed.
      if (selectedDays.length != 7) {
        throw DataImportException(
            '"treatmentPlan.selectedDays" in treatment #${index + 1} must have exactly 7 entries (got ${selectedDays.length}).');
      }
      for (var j = 0; j < selectedDays.length; j++) {
        if (selectedDays[j] is! bool) {
          throw DataImportException(
              '"treatmentPlan.selectedDays[$j]" in treatment #${index + 1} must be a boolean (got ${selectedDays[j].runtimeType}).');
        }
      }
    }
  }

  /// Mirrors `MedicineInventorySerialization.fromJson` + nested
  /// `MedicineSerialization.fromJson` and `SpecificationSerialization.fromJson`
  /// (lib/features/pillbox/data/pillbox_model.dart:80-115). Note: this box
  /// uses the key `specs` (not `specification`).
  static void _validatePillboxEntry(dynamic entry, int index) {
    if (entry is! Map) {
      throw DataImportException(
          'Pillbox entry #${index + 1} is not an object.');
    }
    final medicine = entry['medicine'];
    if (medicine is! Map) {
      throw DataImportException(
          'Pillbox entry #${index + 1} is missing "medicine".');
    }
    _requireInt(entry['quantity'], 'quantity', 'pillbox entry #${index + 1}');

    _requireString(
        medicine['name'], 'medicine.name', 'pillbox entry #${index + 1}');
    _requireString(
        medicine['type'], 'medicine.type', 'pillbox entry #${index + 1}');
    _requireString(
        medicine['color'], 'medicine.color', 'pillbox entry #${index + 1}');

    final specs = medicine['specs'];
    if (specs is! Map) {
      throw DataImportException(
          'Pillbox entry #${index + 1} is missing "medicine.specs".');
    }
    _requireNum(specs['dosage'], 'medicine.specs.dosage',
        'pillbox entry #${index + 1}');
    _requireString(
        specs['unit'], 'medicine.specs.unit', 'pillbox entry #${index + 1}');
    // useCase is optional in SpecificationSerialization (defaults to '').
  }

  static void _requireString(dynamic value, String field, String location) {
    if (value is! String) {
      throw DataImportException(
          '"$field" in $location must be a string (got ${value.runtimeType}).');
    }
  }

  static void _requireNum(dynamic value, String field, String location) {
    if (value is! num) {
      throw DataImportException(
          '"$field" in $location must be a number (got ${value.runtimeType}).');
    }
  }

  static void _requireInt(dynamic value, String field, String location) {
    if (value is! int) {
      throw DataImportException(
          '"$field" in $location must be an integer (got ${value.runtimeType}).');
    }
  }

  static void _requireBool(dynamic value, String field, String location) {
    if (value is! bool) {
      throw DataImportException(
          '"$field" in $location must be a boolean (got ${value.runtimeType}).');
    }
  }

  static void _requireDateString(
      dynamic value, String field, String location) {
    if (value is! String) {
      throw DataImportException(
          '"$field" in $location must be an ISO-8601 date string (got ${value.runtimeType}).');
    }
    if (DateTime.tryParse(value) == null) {
      throw DataImportException(
          '"$field" in $location is not a valid date: "$value".');
    }
  }
}

class DataImportException implements Exception {
  final String message;
  const DataImportException(this.message);

  @override
  String toString() => message;
}
