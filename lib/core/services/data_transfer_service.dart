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
  /// bad input. Lenient about missing boxes (treated as empty) but strict
  /// about every field `Treatment.fromJson` and `MedicineInventorySerialization.fromJson`
  /// require — both catch their own parse failures and fall back to
  /// placeholder objects, which would silently replace the user's real data
  /// after we've already wiped Hive.
  static void _spotCheckShapes(Map<String, dynamic> boxes) {
    final treatmentsBox = boxes[HiveService.treatmentsBoxName];
    if (treatmentsBox is Map) {
      final list = treatmentsBox['treatments'];
      if (list != null && list is! List) {
        throw const DataImportException(
            'Export file is malformed: "treatments" should be a list.');
      }
      if (list is List) {
        for (var i = 0; i < list.length; i++) {
          _validateTreatmentEntry(list[i], i);
        }
      }
    }

    final pillboxBox = boxes[HiveService.pillboxBoxName];
    if (pillboxBox is Map) {
      final list = pillboxBox['pillbox'];
      if (list != null && list is! List) {
        throw const DataImportException(
            'Export file is malformed: "pillbox" should be a list.');
      }
      if (list is List) {
        for (var i = 0; i < list.length; i++) {
          _validatePillboxEntry(list[i], i);
        }
      }
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
