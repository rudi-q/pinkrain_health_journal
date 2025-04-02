import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pillow/features/journal/data/journal_log.dart';
import 'package:pillow/alarm_experiments.dart' as notification_impl;
import 'package:pillow/core/util/helpers.dart';

/// Service to handle medication notifications
/// This service uses the NotificationService from alarm_experiments.dart
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

  // Track which medications we've already notified for today
  final Set<String> _notifiedMedicationIds = {};

  /// Initialize the notification service
  Future<void> initialize() async {
    await _notificationService.initialize();

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
  /// This will only show notifications for medications that haven't been taken
  /// and that haven't already been notified for today
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

    // Start with a high ID to avoid conflicts with other notifications
    int notificationId = 100;

    // Print debug info
    devPrint('📋 Checking ${medications.length} medications for notifications');
    int untakenCount = medications.where((med) => !med.isTaken).length;
    devPrint('📋 Found $untakenCount untaken medications');

    for (var medication in medications) {
      // Only show notifications for untaken medications
      if (!medication.isTaken) {
        // Create a unique ID for this medication to avoid duplicates
        final medicationId =
            '${medication.treatment.medicine.name}_${DateTime.now().day}';

        // Check if we've already notified for this medication today
        if (!_notifiedMedicationIds.contains(medicationId)) {
          devPrint(
              '🔔 Showing notification for: ${medication.treatment.medicine.name}');

          await _showMedicationNotification(
            id: notificationId,
            title: 'Medication Reminder',
            body: 'Remember to take ${medication.treatment.medicine.name}',
            medicationId: medicationId,
          );

          notificationId++;
        } else {
          devPrint(
              '🔕 Already notified for: ${medication.treatment.medicine.name}');
        }
      }
    }
  }

  /// Show a notification for a specific medication
  Future<void> _showMedicationNotification({
    required int id,
    required String title,
    required String body,
    required String medicationId,
  }) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pill_channel_id', // Channel ID
      'Pill Reminders', // Channel name
      channelDescription: 'Reminders for taking your pills',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ticker:
          'Pill Reminder', // For accessibility and also appears in status bar
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Show the notification
    await FlutterLocalNotificationsPlugin().show(
      id,
      title,
      body,
      notificationDetails,
      payload: 'medication_$medicationId',
    );

    // Mark this medication as notified
    _notifiedMedicationIds.add(medicationId);

    devPrint('✅ Showed medication notification for: $medicationId');
  }

  /// Clear notification tracking at the end of the day
  void resetDailyNotifications() {
    _notifiedMedicationIds.clear();
  }
}
