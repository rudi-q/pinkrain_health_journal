import 'dart:io';
import 'package:hive/hive.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/data/journal_log.dart';
import 'package:pinkrain/features/journal/domain/push_notifications.dart';
import 'package:pinkrain/features/treatment/domain/treatment_manager.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Service responsible for scheduling medication notifications
/// This service follows clean architecture principles by:
/// 1. Using a separate service for scheduling logic
/// 2. Persisting notification data via Hive
/// 3. Maintaining proper separation of concerns
class MedicationSchedulerService {
  static final MedicationSchedulerService _instance = MedicationSchedulerService._internal();
  
  factory MedicationSchedulerService() {
    return _instance;
  }
  
  MedicationSchedulerService._internal();
  
  static const String _boxName = 'medication_scheduler';
  static const String _scheduledNotificationsKey = 'scheduled_notifications';
  
  // Notification text constants (DRY principle)
  static const String _notificationTitleSuffix = ' 💊';
  static const String _notificationBody = 'Don\'t forget to take your medicine!';
  
  final NotificationService _notificationService = NotificationService();
  
  /// Initialize the scheduler service
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    
    // Make sure the notification service is initialized
    await _notificationService.initialize();
    
    // Open Hive box for persistent storage
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    
    // Reset notifications that have passed
    await _cleanupPassedNotifications();
    
    // Restore scheduled notifications on app restart
    // iOS clears scheduled notifications when the app is killed, so we need to reschedule them
    await _restoreScheduledNotifications();
  }
  
  /// Schedule notifications for medications
  /// This method will schedule notifications for each medication
  /// based on its scheduled time for TODAY and future days
  /// CRITICAL FIX: Now schedules for multiple days ahead (14 days) to ensure notifications work even if app isn't opened
  Future<void> scheduleMedicationNotifications(List<IntakeLog> medications) async {
    devPrint('📅 Scheduling notifications for ${medications.length} medications');
    
    final box = await _getBox();
    
    // Clean up expired notifications
    await _cleanupPassedNotifications();
    
    // Get existing scheduled notifications from storage
    // CRITICAL: Reload after cleanup to get the latest state
    final scheduledNotifications = _getScheduledNotifications(box);
    
    // Build a set of already-scheduled medication IDs for quick lookup
    // This prevents duplicate scheduling even if multiple calls happen rapidly
    final alreadyScheduledKeys = scheduledNotifications
        .map((n) => '${n['medicationId']}_${n['scheduledTime']}')
        .toSet();
    
    // Build set of medication IDs we're about to schedule
    final medicationIdsToSchedule = <String>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Track notifications we're scheduling in THIS call to prevent duplicates
    final notificationsScheduledInThisCall = <String>{};
    
    final List<Map<String, dynamic>> newScheduledNotifications = [];
    
    // Get unique treatments from the medications list
    final treatments = medications.map((m) => m.treatment).toSet();
    
    devPrint('📅 Scheduling notifications for ${treatments.length} unique treatments for their entire duration');
    
    // For each treatment, schedule notifications for ALL applicable days in the treatment period
    for (var treatment in treatments) {
      final treatmentPlan = treatment.treatmentPlan;
      final doseTimes = treatmentPlan.getAllDoseTimes();
      
      // CRITICAL FIX: Schedule for the ENTIRE treatment duration, not just a fixed window
      // This ensures notifications work indefinitely, regardless of app usage
      final startDate = DateTime(
        treatmentPlan.startDate.year,
        treatmentPlan.startDate.month,
        treatmentPlan.startDate.day,
      );
      final endDate = DateTime(
        treatmentPlan.endDate.year,
        treatmentPlan.endDate.month,
        treatmentPlan.endDate.day,
      );
      
      // DEBUG: Log treatment dates
      devPrint('📋 Treatment: ${treatment.medicine.name}');
      devPrint('   Start: ${startDate.toString()}');
      devPrint('   End: ${endDate.toString()}');
      devPrint('   Today: ${today.toString()}');
      
      // SAFETY: Limit to 60 days ahead - this is a rolling window that gets refreshed
      // This prevents scheduling thousands of notifications while still ensuring coverage
      // The daily reset and app startup will keep refreshing this window
      final maxDate = today.add(const Duration(days: 60)); // 60 days rolling window
      final effectiveEndDate = endDate.isAfter(maxDate) ? maxDate : endDate;
      
      if (endDate.isAfter(maxDate)) {
        devPrint('📅 Treatment end date (${endDate.toString()}) exceeds 60-day window, scheduling up to ${maxDate.toString()}');
        devPrint('   (Window will be refreshed daily to maintain coverage)');
      }
      
      // Start from today or treatment start date, whichever is later
      var currentDate = startDate.isBefore(today) ? today : startDate;
      
      // Validate dates are reasonable
      if (currentDate.isAfter(effectiveEndDate)) {
        devPrint('⚠️ Skipping treatment ${treatment.medicine.name}: start date is after end date');
        continue;
      }
      
      // Schedule for each day in the treatment period (up to 60-day window)
      int daysScheduled = 0;
      const maxDaysToSchedule = 60; // 60-day rolling window
      
      while ((currentDate.isBefore(effectiveEndDate) || currentDate.isAtSameMomentAs(effectiveEndDate)) && 
             daysScheduled < maxDaysToSchedule) {
        // Check if treatment should be taken on this date
        if (!treatmentPlan.shouldTakeOnDate(currentDate)) {
          currentDate = currentDate.add(const Duration(days: 1));
          daysScheduled++;
          continue; // Skip days when treatment shouldn't be taken
        }
        
        // Schedule for each dose time
        for (var doseTime in doseTimes) {
          final scheduledTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            doseTime.hour,
            doseTime.minute,
          );
          
          // Skip past times (but allow today's future times)
          if (scheduledTime.isBefore(now)) {
            continue;
          }
          
          // Create unique ID using full date (YYYYMMDD) and time (HHMM) to prevent conflicts
          final dateKey = '${scheduledTime.year}${scheduledTime.month.toString().padLeft(2, '0')}${scheduledTime.day.toString().padLeft(2, '0')}';
          final timeKey = '${scheduledTime.hour.toString().padLeft(2, '0')}${scheduledTime.minute.toString().padLeft(2, '0')}';
          final treatmentId = treatment.id;
          final medicationId = treatmentId.isNotEmpty 
              ? '${treatmentId}_${dateKey}_$timeKey'
              : '${treatment.medicine.name}_${dateKey}_$timeKey';
          
          medicationIdsToSchedule.add(medicationId);
          
          // CRITICAL: Check if we already have this exact notification scheduled
          // Use both medicationId AND scheduledTime to create a unique key
          final notificationKey = '${medicationId}_${scheduledTime.millisecondsSinceEpoch}';
          
          // Check if already scheduled in our storage
          final existingNotification = scheduledNotifications.firstWhere(
            (n) => n['medicationId'] == medicationId && 
                   n['scheduledTime'] == scheduledTime.millisecondsSinceEpoch,
            orElse: () => <String, dynamic>{},
          );
          
          // Also check our quick lookup set (for rapid duplicate prevention)
          final isAlreadyScheduled = alreadyScheduledKeys.contains(notificationKey);
          
          // Check if we've already scheduled this in THIS call (prevents duplicates within same execution)
          final alreadyScheduledInThisCall = notificationsScheduledInThisCall.contains(notificationKey);
          
          // Only schedule if we don't already have it (in storage, in system, or in this call)
          // OR if it's for today (to handle status changes like taken/skipped)
          final isToday = currentDate.isAtSameMomentAs(today);
          if ((existingNotification.isEmpty && !isAlreadyScheduled && !alreadyScheduledInThisCall) || isToday) {
            // For today, check if medication is taken/skipped from the provided list
            if (isToday) {
              final todayMedication = medications.firstWhere(
                (m) => m.treatment.id == treatment.id && 
                       (m.doseTime?.hour == doseTime.hour && m.doseTime?.minute == doseTime.minute || 
                        (m.doseTime == null && treatmentPlan.timeOfDay.hour == doseTime.hour && treatmentPlan.timeOfDay.minute == doseTime.minute)),
                orElse: () => IntakeLog(treatment, doseTime: doseTime),
              );
              
              // Skip if already taken or skipped
              if (todayMedication.isTaken || todayMedication.isSkipped) {
                devPrint('⏭️ Skipping taken/skipped medication: ${treatment.medicine.name} at ${scheduledTime.toString()}');
                continue;
              }
            }
            
            // Generate a deterministic ID for the notification based on medicationId and time
            // This ensures scheduling the same notification multiple times will replace it, not duplicate it
            final notificationId = _generateNotificationId(
              medicationId: medicationId,
              scheduledTimeMs: scheduledTime.millisecondsSinceEpoch,
            );
            
            // Schedule the notification at the exact scheduled time
            await _scheduleNotification(
              id: notificationId,
              title: 'Take your ${treatment.medicine.name}$_notificationTitleSuffix',
              body: _notificationBody,
              scheduledTime: scheduledTime,
              payload: {
                'medicationId': medicationId,
                'type': 'main',
                'notificationId': notificationId.toString(),
                'snooze': true,
              },
            );
            
            // Track the scheduled notification
            final newNotification = {
              'id': notificationId,
              'medicationId': medicationId,
              'scheduledTime': scheduledTime.millisecondsSinceEpoch,
              'type': 'main',
            };
            newScheduledNotifications.add(newNotification);
            
            // Add to our quick lookup sets to prevent duplicates
            alreadyScheduledKeys.add(notificationKey);
            notificationsScheduledInThisCall.add(notificationKey);
            
            devPrint('🔔 Scheduled notification for ${treatment.medicine.name} at ${scheduledTime.toString()}');
          } else {
            // Keep the existing notification
            newScheduledNotifications.add(existingNotification);
          }
        }
        
        // Move to next day
        currentDate = currentDate.add(const Duration(days: 1));
        daysScheduled++;
      }
      
      if (daysScheduled >= maxDaysToSchedule) {
        devPrint('⚠️ Reached scheduling limit for ${treatment.medicine.name} ($daysScheduled days)');
      }
    }
    
    // Build a set of keys for notifications we're keeping (same medicationId + scheduledTime)
    // These are existing notifications that we found and decided to keep
    final keptNotificationKeys = <String>{};
    for (final newNotif in newScheduledNotifications) {
      final existing = scheduledNotifications.firstWhere(
        (n) => n['medicationId'] == newNotif['medicationId'] && 
               n['scheduledTime'] == newNotif['scheduledTime'],
        orElse: () => <String, dynamic>{},
      );
      if (existing.isNotEmpty) {
        // This is an existing notification we're keeping
        final key = '${newNotif['medicationId']}_${newNotif['scheduledTime']}';
        keptNotificationKeys.add(key);
      }
    }
    
    // Remove old notification records ONLY for medications we're replacing
    // Keep: 1) notifications we're not touching, 2) notifications we're keeping
    final notificationsToKeep = scheduledNotifications.where((notification) {
      final medicationId = notification['medicationId'] as String? ?? '';
      
      // Keep if it's not in the set we're scheduling (not touching it at all)
      if (!medicationIdsToSchedule.contains(medicationId)) {
        return true;
      }
      
      // Keep if this exact notification is being kept (same medicationId and time)
      final key = '${notification['medicationId']}_${notification['scheduledTime']}';
      if (keptNotificationKeys.contains(key)) {
        return true;
      }
      
      // Otherwise, we're replacing it with a new notification
      devPrint('🧹 Removing old record to be replaced: $medicationId');
      return false;
    }).toList();
    
    final removedCount = scheduledNotifications.length - notificationsToKeep.length;
    if (removedCount > 0) {
      devPrint('🧹 Removed $removedCount old records that are being replaced');
    }
    
    // Merge kept notifications with truly new ones
    // Only add notifications that aren't already in keptNotifications
    final keptKeys = notificationsToKeep.map((n) => 
        '${n['medicationId']}_${n['scheduledTime']}').toSet();
    
    final trulyNewNotifications = newScheduledNotifications.where((n) => 
        !keptKeys.contains('${n['medicationId']}_${n['scheduledTime']}')).toList();
    
    if (trulyNewNotifications.length != newScheduledNotifications.length) {
      devPrint('📝 Keeping ${newScheduledNotifications.length - trulyNewNotifications.length} existing notifications, adding ${trulyNewNotifications.length} new ones');
    }
    
    final allNotifications = [...notificationsToKeep, ...trulyNewNotifications];
    
    // Deduplicate all notifications (both kept and newly scheduled)
    final Map<String, Map<String, dynamic>> uniqueNotifications = {};
    
    for (final notification in allNotifications) {
      // IMPROVED DEDUPLICATION: Use medicationId, type, and scheduled time as composite key
      // This ensures we don't have duplicate notifications for the same medication at the same time
      final String compositeKey = '${notification['medicationId']}_${notification['type']}_${notification['scheduledTime']}';
      
      // Keep the notification with the higher ID (more recent) if there are duplicates
      if (!uniqueNotifications.containsKey(compositeKey) || 
          notification['id'] > uniqueNotifications[compositeKey]!['id']) {
        uniqueNotifications[compositeKey] = notification;
      }
    }
    
    // Convert back to list for saving
    final deduplicatedNotifications = uniqueNotifications.values.toList();
    
    final totalRemoved = scheduledNotifications.length - deduplicatedNotifications.length;
    devPrint('💾 Saving ${deduplicatedNotifications.length} scheduled notifications (removed $totalRemoved old/duplicate records)');
    
    // Save the updated list of scheduled notifications
    await _saveScheduledNotifications(box, deduplicatedNotifications);
  }
  
  /// Clean up notifications that have already passed or are beyond 60-day window
  Future<void> _cleanupPassedNotifications() async {
    final box = await _getBox();
    final scheduledNotifications = _getScheduledNotifications(box);
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final maxDate = now.add(const Duration(days: 60));
    final maxDateMs = maxDate.millisecondsSinceEpoch;
    
    // Filter out notifications that have already passed, are beyond 60 days, or are old 'reminder' type
    final activeNotifications = scheduledNotifications.where((notification) {
      final scheduledMs = notification['scheduledTime'] as int;
      final type = notification['type'] ?? 'main';
      
      // Remove old 'reminder' type notifications (we don't use these anymore)
      if (type == 'reminder') {
        return false;
      }
      
      // Remove past notifications
      if (scheduledMs <= nowMs) {
        return false;
      }
      
      // Remove notifications beyond 60-day window
      if (scheduledMs > maxDateMs) {
        return false;
      }
      
      return true;
    }).toList();
    
    final removedCount = scheduledNotifications.length - activeNotifications.length;
    if (removedCount > 0) {
      devPrint('🧹 Cleaned up $removedCount passed/old notifications');
      
      // Also cancel these from the system notification manager
      for (var notification in scheduledNotifications) {
        final scheduledMs = notification['scheduledTime'] as int;
        final type = notification['type'] ?? 'main';
        
        final shouldRemove = scheduledMs <= nowMs || 
                            scheduledMs > maxDateMs || 
                            type == 'reminder';
        
        if (shouldRemove) {
          final int id = notification['id'];
          final medicationId = notification['medicationId'] ?? 'unknown';
          final scheduledDate = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
          if (type == 'reminder') {
            devPrint('   Removing old reminder notification: $medicationId');
          } else if (scheduledMs > maxDateMs) {
            devPrint('   Removing notification beyond 60-day window: $medicationId scheduled for ${scheduledDate.toString()}');
          } else {
            devPrint('   Removing past notification: $medicationId scheduled for ${scheduledDate.toString()}');
          }
          try {
            await _notificationService.cancelReminder(id);
          } catch (e) {
            devPrint('   ⚠️ Error canceling notification $id: $e');
          }
        }
      }
      
      await _saveScheduledNotifications(box, activeNotifications);
    }
  }
  
  /// Restore scheduled notifications from Hive storage
  /// This is critical for iOS where notifications are cleared when the app is killed
  /// CRITICAL FIX: Only restores notifications that aren't already in the system
  Future<void> _restoreScheduledNotifications() async {
    try {
      final box = await _getBox();
      final scheduledNotifications = _getScheduledNotifications(box);
      
      devPrint('🔄 Restoring scheduled notifications from storage');
      
      // Load treatments to get medicine names
      final treatmentManager = TreatmentManager();
      await treatmentManager.loadTreatments();
      
      // Get all currently scheduled notifications from the system
      // We'll check against these to avoid duplicates
      final now = DateTime.now();
      int restoredCount = 0;
      int skippedCount = 0;
      
      for (var notification in scheduledNotifications) {
        try {
          final int id = notification['id'];
          final String medicationId = notification['medicationId'] ?? '';
          final int scheduledTimeMs = notification['scheduledTime'];
          
          final scheduledTime = DateTime.fromMillisecondsSinceEpoch(scheduledTimeMs);
          
          // Only restore if the notification is still in the future AND within 60 days
          final daysAhead = scheduledTime.difference(now).inDays;
          if (scheduledTime.isAfter(now) && daysAhead <= 60) {
            // Extract treatment ID from medicationId (format: {treatmentId}_{date}_{time})
            final treatmentId = medicationId.split('_').first;
            
            // Find the treatment to get the actual medicine name
            String medicineName = 'Medication';
            try {
              final treatment = treatmentManager.treatments.firstWhere(
                (t) => t.id == treatmentId,
                orElse: () => treatmentManager.treatments.firstWhere(
                  (t) => medicationId.startsWith(t.medicine.name),
                  orElse: () => throw Exception('Treatment not found'),
                ),
              );
              medicineName = treatment.medicine.name;
            } catch (e) {
              // Fallback: try to extract from medicationId if it starts with a name
              if (medicationId.contains('_')) {
                final parts = medicationId.split('_');
                // If first part is not numeric, it might be a medicine name
                if (parts.isNotEmpty && !RegExp(r'^\d+$').hasMatch(parts.first)) {
                  medicineName = parts.first;
                }
              }
              devPrint('⚠️ Could not find treatment for ID $treatmentId, using fallback name');
            }
            
            // Build notification title and body using constants
            final title = 'Take your $medicineName$_notificationTitleSuffix';
            final body = _notificationBody;
            
            // Reschedule the notification
            await _scheduleNotification(
              id: id,
              title: title,
              body: body,
              scheduledTime: scheduledTime,
              payload: {
                'medicationId': medicationId,
                'type': 'main',
                'notificationId': id.toString(),
                'medicationName': medicineName,
                'snooze': true,
              },
            );
            
            restoredCount++;
            devPrint('✅ Restored notification: $title for $scheduledTime');
          } else {
            if (daysAhead > 60) {
              skippedCount++;
              devPrint('⏭️ Skipping notification beyond 60-day window: $medicationId at $scheduledTime ($daysAhead days ahead)');
            } else {
              devPrint('⏰ Skipping past notification: $medicationId at $scheduledTime');
            }
          }
        } catch (e) {
          devPrint('❌ Error restoring individual notification: $e');
        }
      }
      
      devPrint('✅ Restored $restoredCount scheduled notifications from storage (skipped $skippedCount beyond window)');
      
      // CRITICAL FIX: Only ensure future notifications if we have very few scheduled
      // This prevents re-scheduling thousands of notifications on every app start
      final allScheduled = _getScheduledNotifications(box);
      final futureScheduled = allScheduled.where((n) {
        final scheduledMs = n['scheduledTime'] as int;
        final scheduledTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
        return scheduledTime.isAfter(now) && scheduledTime.difference(now).inDays <= 60;
      }).length;
      
      // Only check for missing notifications if we have less than 30 future notifications
      // This prevents the endless scheduling loop
      if (futureScheduled < 30) {
        devPrint('🔍 Only $futureScheduled future notifications found (within 60 days), checking for missing ones...');
        await _ensureFutureNotificationsScheduled();
      } else {
        devPrint('✅ Already have $futureScheduled future notifications scheduled (within 60 days), skipping gap check');
      }
      
    } catch (e) {
      devPrint('❌ Error restoring scheduled notifications: $e');
    }
  }
  
  /// Ensure all future notifications are scheduled for active treatments
  /// This is called after restoring to fill in any gaps
  Future<void> _ensureFutureNotificationsScheduled() async {
    try {
      devPrint('🔍 Checking for missing future notifications...');
      
      // Load all active treatments
      final treatmentManager = TreatmentManager();
      await treatmentManager.loadTreatments();
      final activeTreatments = treatmentManager.treatments.where((treatment) {
        return treatment.treatmentPlan.isOnGoing();
      }).toList();
      
      if (activeTreatments.isEmpty) {
        devPrint('📭 No active treatments found');
        return;
      }
      
      devPrint('📋 Found ${activeTreatments.length} active treatments');
      
      // Get current scheduled notifications
      final box = await _getBox();
      final scheduledNotifications = _getScheduledNotifications(box);
      final scheduledMedicationIds = scheduledNotifications
          .map((n) => n['medicationId'] as String? ?? '')
          .toSet();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int newNotificationsCount = 0;
      
      // For each active treatment, check if we have all future notifications
      for (var treatment in activeTreatments) {
        final treatmentPlan = treatment.treatmentPlan;
        final doseTimes = treatmentPlan.getAllDoseTimes();
        
        final startDate = DateTime(
          treatmentPlan.startDate.year,
          treatmentPlan.startDate.month,
          treatmentPlan.startDate.day,
        );
        final endDate = DateTime(
          treatmentPlan.endDate.year,
          treatmentPlan.endDate.month,
          treatmentPlan.endDate.day,
        );
        
        // SAFETY: Limit to 60 days ahead - same rolling window as main scheduling
        final maxDate = today.add(const Duration(days: 60)); // 60 days rolling window
        final effectiveEndDate = endDate.isAfter(maxDate) ? maxDate : endDate;
        
        // Start from today or treatment start date, whichever is later
        var currentDate = startDate.isBefore(today) ? today : startDate;
        
        // Validate dates are reasonable
        if (currentDate.isAfter(effectiveEndDate)) {
          devPrint('⚠️ Skipping treatment ${treatment.medicine.name}: start date is after end date');
          continue;
        }
        
        // Check if we already have notifications scheduled for the near future
        // If we have notifications scheduled for the next 30 days, we're good
        final futureNotifications = scheduledNotifications.where((n) {
          final scheduledMs = n['scheduledTime'] as int;
          final scheduledTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
          final treatmentId = treatment.id;
          final medicationIdPrefix = treatmentId.isNotEmpty ? treatmentId : treatment.medicine.name;
          final medicationId = n['medicationId'] as String? ?? '';
          return medicationId.startsWith(medicationIdPrefix) && 
                 scheduledTime.isAfter(now) && 
                 scheduledTime.isBefore(today.add(const Duration(days: 30)));
        }).length;
        
        // If we already have enough notifications scheduled, skip this treatment
        if (futureNotifications >= 30) {
          devPrint('✅ Treatment ${treatment.medicine.name} already has $futureNotifications notifications scheduled, skipping');
          continue;
        }
        
        // Check each day in the treatment period (60-day window)
        int daysChecked = 0;
        const maxDaysToCheck = 60; // 60-day rolling window
        
        while ((currentDate.isBefore(effectiveEndDate) || currentDate.isAtSameMomentAs(effectiveEndDate)) && 
               daysChecked < maxDaysToCheck) {
          if (!treatmentPlan.shouldTakeOnDate(currentDate)) {
            currentDate = currentDate.add(const Duration(days: 1));
            daysChecked++;
            continue;
          }
          
          for (var doseTime in doseTimes) {
            final scheduledTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              doseTime.hour,
              doseTime.minute,
            );
            
            // Skip past times
            if (scheduledTime.isBefore(now)) {
              continue;
            }
            
            // Create medication ID
            final dateKey = '${scheduledTime.year}${scheduledTime.month.toString().padLeft(2, '0')}${scheduledTime.day.toString().padLeft(2, '0')}';
            final timeKey = '${scheduledTime.hour.toString().padLeft(2, '0')}${scheduledTime.minute.toString().padLeft(2, '0')}';
            final treatmentId = treatment.id;
            final medicationId = treatmentId.isNotEmpty 
                ? '${treatmentId}_${dateKey}_$timeKey'
                : '${treatment.medicine.name}_${dateKey}_$timeKey';
            
            // If we don't have this notification scheduled, schedule it
            if (!scheduledMedicationIds.contains(medicationId)) {
              // Generate a deterministic ID based on medicationId and time
              // This ensures the same notification always gets the same ID, preventing duplicates
              final notificationId = _generateNotificationId(
                medicationId: medicationId,
                scheduledTimeMs: scheduledTime.millisecondsSinceEpoch,
              );
              
              await _scheduleNotification(
                id: notificationId,
                title: 'Take your ${treatment.medicine.name}$_notificationTitleSuffix',
                body: _notificationBody,
                scheduledTime: scheduledTime,
                payload: {
                  'medicationId': medicationId,
                  'type': 'main',
                  'notificationId': notificationId.toString(),
                  'snooze': true,
                },
              );
              
              // Save to storage
              final newNotification = {
                'id': notificationId,
                'medicationId': medicationId,
                'scheduledTime': scheduledTime.millisecondsSinceEpoch,
                'type': 'main',
              };
              scheduledNotifications.add(newNotification);
              scheduledMedicationIds.add(medicationId);
              
              newNotificationsCount++;
              devPrint('🔔 Scheduled missing notification: ${treatment.medicine.name} at ${scheduledTime.toString()}');
            }
          }
          
          currentDate = currentDate.add(const Duration(days: 1));
          daysChecked++;
        }
        
        if (daysChecked >= maxDaysToCheck) {
          devPrint('⚠️ Reached checking limit for ${treatment.medicine.name} ($daysChecked days)');
        }
      }
      
      if (newNotificationsCount > 0) {
        await _saveScheduledNotifications(box, scheduledNotifications);
        devPrint('✅ Scheduled $newNotificationsCount missing future notifications');
      } else {
        devPrint('✅ All future notifications are already scheduled');
      }
    } catch (e) {
      devPrint('❌ Error ensuring future notifications: $e');
    }
  }
  
  /// Schedule a notification to be shown at a specific time
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Make sure the payload includes a medicationName field for snooze handling
      // Note: medicationName should already be set by the caller, but this is a fallback
      if (!payload.containsKey('medicationName') && payload.containsKey('medicationId')) {
        // Try to extract from medicationId - but this is just a fallback
        // The actual name should come from the treatment lookup
        final String medicationId = payload['medicationId'] ?? '';
        if (medicationId.isNotEmpty && medicationId.contains('_')) {
          // This is a fallback - ideally medicationName should be set by caller
          payload['medicationName'] = medicationId.split('_').first;
        }
      }

      // Schedule the notification
      // This works on both iOS and Android - iOS uses DarwinNotificationDetails
      // with presentAlert: true, presentBadge: true, presentSound: true
      await _notificationService.schedulePillReminder(
        id,
        title,
        body,
        scheduledTime,
        payload: payload,
      );
      
      devPrint('✅ Scheduled notification: $title for $scheduledTime');
      if (Platform.isIOS) {
        devPrint('📱 iOS: Notification scheduled and will appear on lock screen/notification center');
      }
    } catch (e) {
      devPrint('❌ Error scheduling notification: $e');
    }
  }
  
  /// Generate a unique notification ID for a medication
  /// CRITICAL: For scheduled notifications, use a deterministic ID based on medicationId and time
  /// This ensures that scheduling the same notification multiple times will replace it, not duplicate it
  int _generateNotificationId({String? medicationId, int? scheduledTimeMs}) {
    // If we have medicationId and scheduledTime, create a deterministic ID
    // This ensures the same notification always gets the same ID, preventing duplicates
    if (medicationId != null && scheduledTimeMs != null) {
      // Create a hash-based ID from medicationId and scheduledTime
      // This ensures the same medication at the same time always gets the same notification ID
      final hash = medicationId.hashCode ^ scheduledTimeMs.hashCode;
      // Ensure positive and within 32-bit range, use modulo to keep it reasonable
      return (hash.abs() % 2147483647); // Max 32-bit signed int
    }
    
    // Fallback: Use timestamp-based ID for immediate notifications
    final baseId = DateTime.now().millisecondsSinceEpoch;
    final timeComponent = DateTime.now().millisecondsSinceEpoch % 10000;
    
    // Combine them while ensuring we stay within 32-bit integer range
    return (baseId % 100000) * 10000 + timeComponent;
  }
  
  /// Get the Hive box for notification storage
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }
  
  /// Get the list of scheduled notifications from Hive
  List<Map<String, dynamic>> _getScheduledNotifications(Box box) {
    final data = box.get(_scheduledNotificationsKey);
    if (data == null) {
      return [];
    }
    
    try {
      // Properly convert from dynamic Hive data to typed List<Map<String, dynamic>>
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            // Convert each map to ensure keys are strings
            return item.map((key, value) => MapEntry(key.toString(), value));
          }
          return <String, dynamic>{};
        }).toList();
      }
      devPrint('❌ Invalid data format in Hive storage: expected List but got ${data.runtimeType}');
      return [];
    } catch (e) {
      devPrint('❌ Error retrieving scheduled notifications: $e');
      return [];
    }
  }
  
  /// Save the list of scheduled notifications to Hive
  Future<void> _saveScheduledNotifications(Box box, List<Map<String, dynamic>> notifications) async {
    await box.put(_scheduledNotificationsKey, notifications);
  }
  
  /// Reset scheduled notifications at midnight
  /// This should be called daily to ensure notifications are refreshed
  Future<void> resetScheduledNotifications() async {
    final box = await _getBox();
    await box.put(_scheduledNotificationsKey, []);
    devPrint('🔄 Reset scheduled notifications');
  }
  
  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    final box = await _getBox();
    final scheduledNotifications = _getScheduledNotifications(box);
    
    for (var notification in scheduledNotifications) {
      final int id = notification['id'];
      await _notificationService.cancelReminder(id);
    }
    
    await resetScheduledNotifications();
    devPrint('❌ Cancelled all scheduled notifications');
  }
  
  /// Cancel and remove all scheduled notifications for a specific treatment
  /// This should be called when a treatment is deleted
  Future<void> cancelNotificationsForTreatment(String treatmentId) async {
    if (treatmentId.isEmpty) {
      devPrint('⚠️ Cannot cancel notifications: treatment ID is empty');
      return;
    }
    
    final box = await _getBox();
    final scheduledNotifications = _getScheduledNotifications(box);
    
    // Find and cancel all notifications for this treatment
    final notificationsToCancel = scheduledNotifications.where((notification) {
      final medicationId = notification['medicationId'] as String? ?? '';
      return medicationId.startsWith(treatmentId);
    }).toList();
    
    devPrint('🧹 Canceling ${notificationsToCancel.length} notifications for treatment: $treatmentId');
    
    for (var notification in notificationsToCancel) {
      final int id = notification['id'];
      try {
        await _notificationService.cancelReminder(id);
      } catch (e) {
        devPrint('⚠️ Error canceling notification $id: $e');
      }
    }
    
    // Remove these notifications from storage
    final remainingNotifications = scheduledNotifications.where((notification) {
      final medicationId = notification['medicationId'] as String? ?? '';
      return !medicationId.startsWith(treatmentId);
    }).toList();
    
    await _saveScheduledNotifications(box, remainingNotifications);
    devPrint('✅ Removed ${notificationsToCancel.length} notification records for treatment: $treatmentId');
  }
  
  /// Debug: Print all scheduled notifications
  /// Useful for troubleshooting notification issues
  Future<void> debugPrintScheduledNotifications() async {
    final box = await _getBox();
    final scheduledNotifications = _getScheduledNotifications(box);
    
    devPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    devPrint('📊 SCHEDULED NOTIFICATIONS DEBUG');
    devPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    devPrint('Total scheduled: ${scheduledNotifications.length}');
    devPrint('');
    
    if (scheduledNotifications.isEmpty) {
      devPrint('No scheduled notifications found.');
    } else {
      // Group by medication ID to show duplicates
      final Map<String, List<Map<String, dynamic>>> groupedByMedicationId = {};
      for (var notification in scheduledNotifications) {
        final medicationId = notification['medicationId'] as String? ?? 'unknown';
        groupedByMedicationId.putIfAbsent(medicationId, () => []);
        groupedByMedicationId[medicationId]!.add(notification);
      }
      
      for (var entry in groupedByMedicationId.entries) {
        final medicationId = entry.key;
        final notifications = entry.value;
        
        devPrint('📦 Medication: $medicationId');
        devPrint('   Count: ${notifications.length}${notifications.length > 1 ? " ⚠️ DUPLICATES!" : ""}');
        
        for (var notification in notifications) {
          final id = notification['id'];
          final type = notification['type'] ?? 'unknown';
          final scheduledTimeMs = notification['scheduledTime'] as int;
          final scheduledTime = DateTime.fromMillisecondsSinceEpoch(scheduledTimeMs);
          final isPast = scheduledTime.isBefore(DateTime.now());
          
          devPrint('   - ID: $id, Type: $type, Time: ${scheduledTime.toString()}${isPast ? " (PAST)" : ""}');
        }
        devPrint('');
      }
    }
    devPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
  
  /// One-time cleanup: Remove duplicate notification records
  /// This can be called once to fix existing duplicate issues
  Future<int> cleanupDuplicateNotifications() async {
    final box = await _getBox();
    final scheduledNotifications = _getScheduledNotifications(box);
    
    devPrint('🧹 Starting duplicate notification cleanup...');
    devPrint('   Found ${scheduledNotifications.length} total notification records');
    
    // Use the same deduplication logic as scheduleMedicationNotifications
    final Map<String, Map<String, dynamic>> uniqueNotifications = {};
    
    for (final notification in scheduledNotifications) {
      final String compositeKey = '${notification['medicationId']}_${notification['type']}_${notification['scheduledTime']}';
      
      // Keep the notification with the higher ID (more recent) if there are duplicates
      if (!uniqueNotifications.containsKey(compositeKey) || 
          notification['id'] > uniqueNotifications[compositeKey]!['id']) {
        
        // If replacing, cancel the old one
        if (uniqueNotifications.containsKey(compositeKey)) {
          final oldId = uniqueNotifications[compositeKey]!['id'];
          try {
            await _notificationService.cancelReminder(oldId);
          } catch (e) {
            devPrint('   ⚠️ Error canceling old duplicate notification $oldId: $e');
          }
        }
        
        uniqueNotifications[compositeKey] = notification;
      } else {
        // Cancel the duplicate notification
        final duplicateId = notification['id'];
        try {
          await _notificationService.cancelReminder(duplicateId);
        } catch (e) {
          devPrint('   ⚠️ Error canceling duplicate notification $duplicateId: $e');
        }
      }
    }
    
    final deduplicatedNotifications = uniqueNotifications.values.toList();
    final removedCount = scheduledNotifications.length - deduplicatedNotifications.length;
    
    // Save the cleaned list
    await _saveScheduledNotifications(box, deduplicatedNotifications);
    
    devPrint('✅ Cleanup complete: Removed $removedCount duplicate notification records');
    devPrint('   Remaining: ${deduplicatedNotifications.length} unique notifications');
    
    return removedCount;
  }
}
