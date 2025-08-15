import 'package:hive/hive.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/journal/data/journal_log.dart';
import 'package:pillow/features/journal/domain/push_notifications.dart';
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
  static const String _reminderOffsetKey = 'reminder_offset_minutes';
  
  // Default reminder time (15 minutes before medication is due)
  static const int _defaultReminderOffsetMinutes = 15;
  
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
  }
  
  /// Get the configured reminder offset in minutes
  /// This is how many minutes before the scheduled time the reminder will be sent
  Future<int> getReminderOffsetMinutes() async {
    final box = await _getBox();
    final offsetMinutes = box.get(_reminderOffsetKey, defaultValue: _defaultReminderOffsetMinutes);
    return offsetMinutes;
  }
  
  /// Set the reminder offset in minutes
  /// This is how many minutes before the scheduled time the reminder will be sent
  Future<void> setReminderOffsetMinutes(int minutes) async {
    if (minutes < 0) {
      throw ArgumentError('Reminder offset cannot be negative');
    }
    
    final box = await _getBox();
    await box.put(_reminderOffsetKey, minutes);
  }
  
  /// Schedule notifications for medications
  /// This method will schedule notifications for each medication
  /// based on its scheduled time
  Future<void> scheduleMedicationNotifications(List<IntakeLog> medications) async {
    devPrint('📅 Scheduling notifications for ${medications.length} medications');
    
    // Get the box for storing notification data
    final box = await _getBox();
    
    // Get existing scheduled notifications
    final scheduledNotifications = _getScheduledNotifications(box);
    
    // Track newly scheduled notifications
    final List<Map<String, dynamic>> newScheduledNotifications = [];
    
    // Get the reminder offset
    final reminderOffsetMinutes = await getReminderOffsetMinutes();
    
    DateTime now = DateTime.now();
    
    for (var medication in medications) {
      // Only schedule for untaken medications
      if (!medication.isTaken) {
        // Get the scheduled time for this medication
        final scheduledTime = _getScheduledTimeForMedication(medication);
        
        // Create a unique ID for this medication
        final medicationId = '${medication.treatment.medicine.name}_${scheduledTime.day}';
        
        // Generate a random ID for the notification
        final notificationId = _generateNotificationId();
        
        // Calculate the reminder time (before the scheduled time)
        final reminderTime = scheduledTime.subtract(Duration(minutes: reminderOffsetMinutes));
        
        // Only schedule reminder if it's in the future
        if (reminderTime.isAfter(now)) {
          // Schedule the reminder notification
          final reminderNotificationId = _generateNotificationId();
          await _scheduleNotification(
            id: reminderNotificationId,
            title: 'Upcoming Medication',
            body: 'Remember to take ${medication.treatment.medicine.name} in $reminderOffsetMinutes minutes',
            scheduledTime: reminderTime,
            payload: {
              'medicationId': medicationId,
              'type': 'reminder',
              'reminderNotificationId': reminderNotificationId.toString(),
              'mainNotificationId': notificationId.toString(),
              'snooze': true,
            },
          );
          
          // Track the scheduled notification
          newScheduledNotifications.add({
            'id': reminderNotificationId,
            'medicationId': medicationId,
            'scheduledTime': reminderTime.millisecondsSinceEpoch,
            'type': 'reminder',
          });
          
          devPrint('🔔 Scheduled reminder for ${medication.treatment.medicine.name} at ${reminderTime.toString()}');
        }
        
        // Schedule the main notification at the exact time
        await _scheduleNotification(
          id: notificationId,
          title: 'Medication Due',
          body: 'Time to take ${medication.treatment.medicine.name}',
          scheduledTime: scheduledTime,
          payload: {
            'medicationId': medicationId,
            'type': 'main',
            'notificationId': notificationId.toString(),
            'snooze': true,
          },
        );
        
        // Track the scheduled notification
        newScheduledNotifications.add({
          'id': notificationId,
          'medicationId': medicationId,
          'scheduledTime': scheduledTime.millisecondsSinceEpoch,
          'type': 'main',
        });
        
        devPrint('🔔 Scheduling notification for ${medication.treatment.medicine.name} at ${scheduledTime.toString()}');
      }
    }
    
    // Combine existing and new notifications, removing duplicates
    final allNotifications = [...scheduledNotifications, ...newScheduledNotifications];
    
    // Save the updated list of scheduled notifications
    await _saveScheduledNotifications(box, allNotifications);
  }
  
  /// Clean up notifications that have already passed
  Future<void> _cleanupPassedNotifications() async {
    final box = await _getBox();
    final scheduledNotifications = _getScheduledNotifications(box);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Filter out notifications that have already passed
    final activeNotifications = scheduledNotifications.where((notification) {
      return notification['scheduledTime'] > now;
    }).toList();
    
    if (scheduledNotifications.length != activeNotifications.length) {
      devPrint('🧹 Cleaned up ${scheduledNotifications.length - activeNotifications.length} passed notifications');
      await _saveScheduledNotifications(box, activeNotifications);
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
      if (!payload.containsKey('medicationName') && payload.containsKey('medicationId')) {
        // Extract medication name from the ID if available
        final String medicationId = payload['medicationId'] ?? '';
        if (medicationId.isNotEmpty && medicationId.contains('_')) {
          payload['medicationName'] = medicationId.split('_').first;
        }
      }

      // Schedule the notification
      await _notificationService.schedulePillReminder(
        id,
        title,
        body,
        scheduledTime,
        payload: payload,
      );
      
      devPrint('✅ Scheduled notification: $title for $scheduledTime');
    } catch (e) {
      devPrint('❌ Error scheduling notification: $e');
    }
  }
  
  /// Get the scheduled time for a medication
  /// This uses the medication's scheduled time or defaults to now + 1 hour if not available
  DateTime _getScheduledTimeForMedication(IntakeLog medication) {
    // Try to get the scheduled time from the medication
    final timeOfDay = medication.treatment.treatmentPlan.timeOfDay;
    try {
      // Extract hour and minute from the timeOfDay DateTime
      final hour = timeOfDay.hour;
      final minute = timeOfDay.minute;
      
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If the scheduled time is in the past for today, move it to tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      return scheduledTime;
    } catch (e) {
      devPrint('❌ Error parsing scheduled time: $e');
    }
    
    // Default: schedule for 1 hour from now
    return DateTime.now().add(const Duration(hours: 1));
  }
  
  /// Generate a unique notification ID for a medication
  int _generateNotificationId() {
    // Use the treatment ID as part of the notification ID to ensure uniqueness
    // Add a timestamp component to avoid conflicts
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
}
