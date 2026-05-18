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

  /// Reject obviously malformed exports up-front so we never enter the wipe
  /// path on bad input. Lenient about missing boxes (treated as empty) but
  /// strict about the shape of present treatments since `Treatment.fromJson`
  /// is the most fragile downstream reader.
  static void _spotCheckShapes(Map<String, dynamic> boxes) {
    final treatmentsBox = boxes[HiveService.treatmentsBoxName];
    if (treatmentsBox is Map) {
      final list = treatmentsBox['treatments'];
      if (list != null && list is! List) {
        throw const DataImportException(
            'Export file is malformed: "treatments" should be a list.');
      }
      if (list is List) {
        for (final entry in list) {
          if (entry is! Map) {
            throw const DataImportException(
                'Export file is malformed: a treatment entry is not an object.');
          }
          if (entry['medicine'] is! Map ||
              entry['treatmentPlan'] is! Map) {
            throw const DataImportException(
                'Export file is malformed: a treatment is missing required fields.');
          }
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
    }
  }
}

class DataImportException implements Exception {
  final String message;
  const DataImportException(this.message);

  @override
  String toString() => message;
}
