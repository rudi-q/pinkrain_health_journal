import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/data/journal_log.dart';
import 'package:pinkrain/features/journal/domain/push_notifications.dart' as notification_impl;
import 'package:pinkrain/features/treatment/services/medication_scheduler_service.dart';

/// Service to handle medication notifications
/// This service uses the NotificationService from push_notifications.dart
/// to show notifications for untaken medications
class MedicationNotificationService {
  static final MedicationNotificationService _instance =
      MedicationNotificationService._internal();

  factory MedicationNotificationService() {
    return _instance;
  }

  MedicationNotificationService._internal();

  // Use the existing notification service implementation
  final _notificationService = notification_impl.NotificationService();

  // Use the new scheduler service for scheduling notifications
  final _schedulerService = MedicationSchedulerService();

  // Track which medications we've already notified for today.
  // This is an in-memory write-through cache backed by Hive (see [_trackingBoxName]).
  final Set<String> _notifiedMedicationIds = {};

  // Track last scheduling time to prevent duplicate rapid schedules
  DateTime? _lastScheduleTime;
  int? _lastMedicationCount;
  static const Duration _scheduleDebounceTime = Duration(seconds: 2);

  // --- Persistent dedupe set ---
  // The set lives in Hive under `notified_<yyyy-MM-dd>` so it segregates by day
  // and naturally ages out via the prune on init. Writes are fire-and-forget
  // (`unawaited`) because the in-memory set is the source of truth within the
  // running process — Hive is only consulted on cold start (singleton resurrection)
  // to repopulate the cache.
  static const String _trackingBoxName = 'notification_tracking';
  static const String _trackingKeyPrefix = 'notified_';

  // Chain of in-flight Hive writes, exposed via [pendingWrites] for tests so they
  // can await fire-and-forget persistence without leaking the implementation detail.
  Future<void> _pendingWrites = Future<void>.value();

  /// Visible for testing — await any in-flight fire-and-forget Hive writes.
  @visibleForTesting
  Future<void> get pendingWrites => _pendingWrites;

  String _todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '$_trackingKeyPrefix${DateFormat('yyyy-MM-dd').format(d)}';
  }

  /// Open (or reuse) the persistent tracking box.
  /// Mirrors the lazy-open pattern used by [MedicationSchedulerService._getBox].
  Future<Box> _getTrackingBox() async {
    if (!Hive.isBoxOpen(_trackingBoxName)) {
      return await Hive.openBox(_trackingBoxName);
    }
    return Hive.box(_trackingBoxName);
  }

  /// Read today's bucket from Hive as a list of medication-id strings.
  List<String> _readBucket(Box box, String key) {
    final raw = box.get(key);
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }

  /// Queue a Hive mutation behind the previous one so tests can await
  /// [pendingWrites] and observe a quiescent state.
  void _enqueueWrite(Future<void> Function() op) {
    _pendingWrites = _pendingWrites.then((_) => op()).catchError((Object e, StackTrace st) {
      devPrint('❌ Error persisting notification tracking: $e');
    });
  }

  /// Persist the current in-memory set to today's Hive bucket.
  Future<void> _persistTodaySnapshot() async {
    try {
      final box = await _getTrackingBox();
      await box.put(_todayKey(), _notifiedMedicationIds.toList(growable: false));
    } catch (e) {
      devPrint('❌ Error writing notification tracking snapshot: $e');
    }
  }

  /// Delete today's Hive bucket (used by resetDailyNotifications).
  Future<void> _deleteTodayBucket() async {
    try {
      final box = await _getTrackingBox();
      await box.delete(_todayKey());
    } catch (e) {
      devPrint('❌ Error deleting today\'s notification tracking bucket: $e');
    }
  }

  /// Restore today's set from Hive and prune any older date buckets.
  Future<void> _restoreAndPruneTracking() async {
    try {
      final box = await _getTrackingBox();
      final todayKey = _todayKey();

      // Restore today's bucket into the in-memory cache.
      _notifiedMedicationIds
        ..clear()
        ..addAll(_readBucket(box, todayKey));

      // Prune older date buckets — anything keyed with our prefix but not today.
      final stale = box.keys
          .whereType<String>()
          .where((k) => k.startsWith(_trackingKeyPrefix) && k != todayKey)
          .toList(growable: false);
      if (stale.isNotEmpty) {
        await box.deleteAll(stale);
        devPrint('🧹 Pruned ${stale.length} stale notification-tracking bucket(s)');
      }
      devPrint('♻️ Restored ${_notifiedMedicationIds.length} notification-tracking entries from Hive');
    } catch (e) {
      devPrint('❌ Error restoring notification tracking from Hive: $e');
    }
  }

  /// Visible for testing — run only the Hive-side restore/prune step that
  /// `initialize()` performs, without touching platform channels (notification
  /// service or scheduler service init).
  @visibleForTesting
  Future<void> restoreTrackingForTesting() async {
    await _restoreAndPruneTracking();
  }

  /// Visible for testing — seed the in-memory dedupe set and write through to
  /// Hive, simulating what `_showMedicationNotification` would do.
  @visibleForTesting
  void markNotifiedForTesting(String medicationId) {
    _notifiedMedicationIds.add(medicationId);
    _enqueueWrite(_persistTodaySnapshot);
  }

  /// Visible for testing — read the live in-memory set.
  @visibleForTesting
  Set<String> get notifiedMedicationIdsForTesting => Set.unmodifiable(_notifiedMedicationIds);

  /// Visible for testing — clear all state (in-memory + on-disk) and close
  /// the tracking box so the next test can re-init with a fresh Hive instance.
  @visibleForTesting
  Future<void> resetForTesting() async {
    // Drain pending writes before tearing down.
    await _pendingWrites;
    _notifiedMedicationIds.clear();
    _lastScheduleTime = null;
    _lastMedicationCount = null;
    if (Hive.isBoxOpen(_trackingBoxName)) {
      final box = Hive.box(_trackingBoxName);
      await box.clear();
      await box.close();
    }
    _pendingWrites = Future<void>.value();
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize the notification service
    await _notificationService.initialize();

    // Initialize the scheduler service
    await _schedulerService.initialize();

    // Restore the in-memory dedupe set from Hive (survives iOS process
    // recreation) and prune older date buckets.
    await _restoreAndPruneTracking();

    // Check and print notification permission status
    final isEnabled = await areNotificationsEnabled();
    devPrint('🔔 Notifications enabled: $isEnabled');
  }

  /// Check if notifications are enabled for this app
  Future<bool> areNotificationsEnabled() async {
    // Platform-specific logic
    final status = await Permission.notification.status;
    // iOS: rely on permission status (Android system check API not available here)
    if (Platform.isIOS) {
      devPrint('🔍 iOS notification check - Permission: $status');
      return status.isGranted;
    }

    // Android: use system-enabled check
    final systemEnabled = await _notificationService.areNotificationsEnabled();
    devPrint('🔍 Android notification check - System: $systemEnabled, Permission: $status');
    return systemEnabled;
  }

  /// Request notification permissions by directly triggering the Android system dialog
  Future<void> requestNotificationPermissions() async {
    try {
      devPrint('🔔 Requesting notification permissions using permission_handler...');
      
      // Request notification permission using permission_handler
      // This will show the system dialog on Android 13+
      final PermissionStatus status = await Permission.notification.request();
      
      devPrint('🔔 Permission request result: $status');
      
      if (status.isGranted) {
        devPrint('✅ Notification permission granted');
      } else if (status.isDenied) {
        devPrint('❌ Notification permission denied');
      } else if (status.isPermanentlyDenied) {
        devPrint('❌ Notification permission permanently denied. User needs to enable from settings');
      }
      
      // Double-check permission status
      final isEnabled = await areNotificationsEnabled();
      devPrint('🔔 After permission request, notifications enabled: $isEnabled');
    } catch (e) {
      devPrint('❌ Error requesting notification permissions: $e');
      
      // Fall back to the original method if permission_handler fails
      try {
        // Create a simple test notification that will trigger the permission request
        final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);
        
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'pill_channel_id',
          'Pill Reminders',
          channelDescription: 'Reminders for taking your pills',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
        );
        
        final NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
        );
        
        // Show a notification which will trigger the system permission dialog
        await FlutterLocalNotificationsPlugin().show(
          0,  // ID
          'Permission Request', // Title 
          'Please allow notifications for medication reminders', // Body
          notificationDetails,
        );
      } catch (e2) {
        devPrint('❌ Error with fallback notification permission method: $e2');
      }
    }
  }

  /// Show notifications for untaken medications
  /// This will show immediate notifications for overdue medications (>5 min late)
  /// and schedule notifications for upcoming medications at their exact scheduled times
  Future<void> showUntakenMedicationNotifications(
      List<IntakeLog> medications, {
        bool forceReschedule = false,
        bool showImmediateNotifications = true,
      }) async {
    // DEBOUNCE: Prevent duplicate rapid scheduling (unless forced)
    final now = DateTime.now();
    if (!forceReschedule && _lastScheduleTime != null) {
      final timeSinceLastSchedule = now.difference(_lastScheduleTime!);
      if (timeSinceLastSchedule < _scheduleDebounceTime) {
        // Only skip if medication count hasn't changed (ensures new treatments trigger reschedule)
        final untakenCount = medications.where((med) => !med.isTaken && !med.isSkipped).length;
        if (_lastMedicationCount == untakenCount) {
          devPrint('⏸️ Skipping duplicate request (${timeSinceLastSchedule.inMilliseconds}ms since last)');
          return;
        } else {
          devPrint('🔄 Medication count changed: $_lastMedicationCount → $untakenCount');
        }
      }
    }
    
    _lastScheduleTime = now;
    
    // Skip permission check—rely on system to handle permission errors
    // (Test notifications work, so permissions are granted; our check has false negatives)
    devPrint('🔔 Scheduling notifications at ${now.toString()}');
    devPrint('   (trusting system permission handling)');

    // Print debug info
    devPrint('📋 Checking ${medications.length} medications for notifications');
    int untakenCount = medications.where((med) => !med.isTaken).length;
    int unskippedCount = medications.where((med) => !med.isSkipped).length;
    int untakenUnskippedCount = medications.where((med) => !med.isTaken && !med.isSkipped).length;
    devPrint('   Untaken: $untakenCount, Unskipped: $unskippedCount, Both: $untakenUnskippedCount');
    
    // Track medication count for debounce logic
    _lastMedicationCount = untakenUnskippedCount;

    // First, schedule notifications for future medications
    await _schedulerService.scheduleMedicationNotifications(medications);
    
    // Then show immediate notifications for overdue medications (only if requested)
    // We DON'T want to show immediate notifications when just rescheduling after edits
    if (showImmediateNotifications) {
      await _showImmediateNotificationsForOverdueMedications(medications);
    } else {
      devPrint('⏭️ Skipping immediate notifications (scheduling only)');
    }
    
    devPrint('✅ Notification scheduling completed');
  }
  
  /// Show immediate notifications for medications that are overdue
  Future<void> _showImmediateNotificationsForOverdueMedications(List<IntakeLog> medications) async {
    // Start with a high ID to avoid conflicts with scheduled notifications
    int notificationId = 10000;
    final now = DateTime.now();
    
    devPrint('🔔 Checking for overdue medications to notify immediately');
    int overdueCount = 0;
    
    for (var medication in medications) {
      // Only show notifications for untaken medications
      if (!medication.isTaken) {
        // Create unique ID using full date (YYYYMMDD) and time (HHMM) to prevent conflicts
        final dateKey = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        final DateTime timeSource = medication.doseTime ?? medication.treatment.treatmentPlan.timeOfDay;
        final timeKey = '${timeSource.hour.toString().padLeft(2, '0')}${timeSource.minute.toString().padLeft(2, '0')}';
        final treatmentId = medication.treatment.id;
        final String medicationId;
        if (treatmentId.isNotEmpty) {
          medicationId = '${treatmentId}_${dateKey}_$timeKey';
        } else {
          // Fallback: use medicine name + start timestamp
          final startTimestamp = medication.treatment.treatmentPlan.startDate.millisecondsSinceEpoch;
          medicationId = '${medication.treatment.medicine.name}_${startTimestamp}_${dateKey}_$timeKey';
        }
        
        // Check if we've already notified for this medication today
        if (!_notifiedMedicationIds.contains(medicationId)) {
          // Only show immediate notifications for overdue medications (>5 min past scheduled time)
          bool isOverdue = false;
          
          // Use the specific doseTime if available (for multi-dose treatments)
          final DateTime timeSource = medication.doseTime ?? medication.treatment.treatmentPlan.timeOfDay;
          try {
            // Extract hour and minute from the timeOfDay DateTime
            final hour = timeSource.hour;
            final minute = timeSource.minute;
            
            final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
            // Consider medication overdue if it's more than 5 minutes past scheduled time
            // This gives a grace period for scheduled notifications to fire first
            final timePastScheduled = now.difference(scheduledTime);
            isOverdue = timePastScheduled > const Duration(minutes: 5);
          } catch (e) {
            devPrint('❌ Error parsing scheduled time: $e');
            // Default to showing notification if we can't parse the time
            isOverdue = true;
          }
          
          if (isOverdue) {
            devPrint('🔔 Showing immediate notification for overdue medication: ${medication.treatment.medicine.name}');
            
            // Format the specific dose time for the notification
            final String scheduledTimeStr = '${timeSource.hour.toString().padLeft(2, '0')}:${timeSource.minute.toString().padLeft(2, '0')}';
            
            await _showMedicationNotification(
              id: notificationId,
              title: '${medication.treatment.medicine.name} was scheduled for $scheduledTimeStr',
              body: "You haven't taken your medication yet!",
              medicationId: medicationId,
            );
            
            overdueCount++;
            notificationId++;
          } else {
            devPrint('⏳ Medication ${medication.treatment.medicine.name} will fire at scheduled time');
          }
        } else {
          devPrint('🔕 Already notified for: ${medication.treatment.medicine.name}');
        }
      }
    }
    
    devPrint('📊 Immediate notification summary: $overdueCount overdue (upcoming medications will fire at their scheduled times)');
  }

  /// Show a notification for a medication
  Future<void> _showMedicationNotification({
    required int id,
    required String title,
    required String body,
    required String medicationId,
  }) async {
    try {
      // Show the notification
      await _notificationService.showNotification(
        id,
        title,
        body,
        payload: {
          'medicationId': medicationId,
          'notificationId': id.toString(),
          'medicationName': medicationId.split('_').first, // Extract medicine name from the ID
        },
        includeSnoozeAction: true, // Enable snooze button
      );
      
      // Add to our tracking set to avoid duplicates (write-through to Hive)
      _notifiedMedicationIds.add(medicationId);
      _enqueueWrite(_persistTodaySnapshot);

      devPrint('✅ Showed medication notification for: $medicationId');
    } catch (e) {
      devPrint('❌ Error showing notification: $e');
    }
  }

  /// Clear notification tracking for a specific medication
  /// Call this when a medication's schedule is changed
  void clearNotificationForMedication(String medicationId) {
    // Remove all entries that start with this medication ID
    _notifiedMedicationIds.removeWhere((id) => id.startsWith(medicationId));
    // Mirror to Hive: read today's bucket, filter, write back (fire-and-forget).
    _enqueueWrite(() async {
      final box = await _getTrackingBox();
      final key = _todayKey();
      final current = _readBucket(box, key);
      final filtered = current.where((id) => !id.startsWith(medicationId)).toList(growable: false);
      if (filtered.length != current.length) {
        await box.put(key, filtered);
      }
    });
    devPrint('🧹 Cleared notification tracking for: $medicationId');
  }

  /// Clear all notification tracking (useful when rescheduling)
  void clearAllNotificationTracking() {
    _notifiedMedicationIds.clear();
    _lastScheduleTime = null;
    _lastMedicationCount = null;
    // Fire-and-forget: drop today's bucket so a process recreated after this
    // call doesn't restore the cleared entries.
    _enqueueWrite(_deleteTodayBucket);
    devPrint('🧹 Cleared all notification tracking');
  }

  /// Wipe both the in-memory dedupe set and the entire Hive tracking box
  /// from disk. Intended for the "Delete All Data" flow — the routine
  /// `clearAllNotificationTracking` only drops today's bucket via a
  /// fire-and-forget write, which is the right behavior for normal app
  /// usage but leaves disk state if the user is explicitly wiping
  /// everything. This is the heavyweight counterpart.
  Future<void> deleteAllPersistedTracking() async {
    // Drain any pending fire-and-forget writes before we tear down the box,
    // otherwise an in-flight write could re-create the file we just deleted.
    await _pendingWrites;
    _notifiedMedicationIds.clear();
    _lastScheduleTime = null;
    _lastMedicationCount = null;
    try {
      if (Hive.isBoxOpen(_trackingBoxName)) {
        await Hive.box(_trackingBoxName).close();
      }
      await Hive.deleteBoxFromDisk(_trackingBoxName);
      devPrint('🗑️ Deleted notification_tracking box from disk');
    } catch (e) {
      devPrint('⚠️ Error deleting notification_tracking box: $e');
    }
    _pendingWrites = Future<void>.value();
  }

  /// Clear notification tracking at the end of the day
  void resetDailyNotifications() {
    _notifiedMedicationIds.clear();
    _lastScheduleTime = null;
    _lastMedicationCount = null;
    // Explicitly delete today's bucket — yesterday's was already pruned on init,
    // but this avoids ambiguity if the reset fires mid-day for any reason.
    _enqueueWrite(_deleteTodayBucket);
    _schedulerService.resetScheduledNotifications();
  }
  
  /// Cancel and remove all scheduled notifications for a specific treatment
  /// This should be called when a treatment is deleted
  Future<void> cancelNotificationsForTreatment(String treatmentId) async {
    await _schedulerService.cancelNotificationsForTreatment(treatmentId);
    clearNotificationForMedication(treatmentId);
  }
  
  /// Debug: Print all scheduled notifications
  /// Useful for troubleshooting notification issues
  Future<void> debugPrintScheduledNotifications() async {
    await _schedulerService.debugPrintScheduledNotifications();
  }
  
  /// One-time cleanup: Remove duplicate notification records
  /// This can be called once to fix existing duplicate issues
  Future<int> cleanupDuplicateNotifications() async {
    return await _schedulerService.cleanupDuplicateNotifications();
  }
}
