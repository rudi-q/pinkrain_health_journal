import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/journal/data/journal_log.dart';
import 'package:pillow/features/journal/domain/push_notifications.dart' as notification_impl;
import 'package:pillow/features/treatment/services/medication_scheduler_service.dart';

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

  // Track which medications we've already notified for today
  final Set<String> _notifiedMedicationIds = {};

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize the notification service
    await _notificationService.initialize();
    
    // Initialize the scheduler service
    await _schedulerService.initialize();

    // Check and print notification permission status
    final isEnabled = await areNotificationsEnabled();
    devPrint('🔔 Notifications enabled: $isEnabled');
  }

  /// Check if notifications are enabled for this app
  Future<bool> areNotificationsEnabled() async {
    // First check using permission_handler for Android 13+
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    
    // Fall back to the notification service implementation
    return await _notificationService.areNotificationsEnabled();
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
  /// This will both show immediate notifications for overdue medications
  /// and schedule notifications for upcoming medications at their exact times
  Future<void> showUntakenMedicationNotifications(
      List<IntakeLog> medications) async {
    // First check if notifications are enabled
    final bool notificationsEnabled = await areNotificationsEnabled();

    if (!notificationsEnabled) {
      devPrint('⚠️ Notifications are not enabled. Requesting permission...');
      await requestNotificationPermissions();

      // Check again after requesting
      final bool permissionGranted = await areNotificationsEnabled();
      if (!permissionGranted) {
        devPrint('❌ Notification permission denied by user');
        return;
      }
    }

    // Print debug info
    devPrint('📋 Checking ${medications.length} medications for notifications');
    int untakenCount = medications.where((med) => !med.isTaken).length;
    devPrint('📋 Found $untakenCount untaken medications');

    // First, schedule notifications for future medications
    await _schedulerService.scheduleMedicationNotifications(medications);
    
    // Then show immediate notifications for overdue medications
    await _showImmediateNotificationsForOverdueMedications(medications);
  }
  
  /// Show immediate notifications for medications that are overdue
  Future<void> _showImmediateNotificationsForOverdueMedications(List<IntakeLog> medications) async {
    // Start with a high ID to avoid conflicts with scheduled notifications
    int notificationId = 10000;
    final now = DateTime.now();
    
    for (var medication in medications) {
      // Only show notifications for untaken medications
      if (!medication.isTaken) {
        // Create a unique ID for this medication to avoid duplicates
        final medicationId = '${medication.treatment.medicine.name}_${DateTime.now().day}';
        
        // Check if we've already notified for this medication today
        if (!_notifiedMedicationIds.contains(medicationId)) {
          // Check if this medication is overdue (scheduled time has passed)
          bool isOverdue = false;
          
          // Use treatmentPlan.timeOfDay instead of scheduledTime
          final timeOfDay = medication.treatment.treatmentPlan.timeOfDay;
          try {
            // Extract hour and minute from the timeOfDay DateTime
            final hour = timeOfDay.hour;
            final minute = timeOfDay.minute;
            
            final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
            isOverdue = scheduledTime.isBefore(now);
          } catch (e) {
            devPrint('❌ Error parsing scheduled time: $e');
            // Default to showing notification if we can't parse the time
            isOverdue = true;
          }
          
          if (isOverdue) {
            devPrint('🔔 Showing immediate notification for overdue medication: ${medication.treatment.medicine.name}');
            
            await _showMedicationNotification(
              id: notificationId,
              title: 'Medication Reminder',
              body: "You haven't taken ${medication.treatment.medicine.name} yet. It was scheduled for ${medication.treatment.formattedTimeOfDay()}",
              medicationId: medicationId,
            );
            
            notificationId++;
          } else {
            devPrint('⏳ Medication ${medication.treatment.medicine.name} is not overdue yet');
          }
        } else {
          devPrint('🔕 Already notified for: ${medication.treatment.medicine.name}');
        }
      }
    }
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
      
      // Add to our tracking set to avoid duplicates
      _notifiedMedicationIds.add(medicationId);
      
      devPrint('✅ Showed medication notification for: $medicationId');
    } catch (e) {
      devPrint('❌ Error showing notification: $e');
    }
  }

  /// Clear notification tracking at the end of the day
  void resetDailyNotifications() {
    _notifiedMedicationIds.clear();
    _schedulerService.resetScheduledNotifications();
  }
}
