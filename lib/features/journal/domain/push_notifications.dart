import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/util/helpers.dart';
import '../../../features/treatment/services/medication_action_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  NotificationService._internal() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  // We'll use this key in getSelectedSoundPath method implementation when SharedPreferences is properly integrated
  static const String selectedSoundKey = 'selected_notification_sound';

  // Get the selected notification sound path from SharedPreferences
  Future<String?> getSelectedSoundPath() async {
    /*final prefs = await SharedPreferences.getInstance();
    return prefs.getString(selectedSoundKey);*/
    return 'pill_alarm';
  }

  Future<void> _init() async {
    // Initialize timezone data first
    tz_data.initializeTimeZones();
    
    // Initialize Android settings with the correct icon
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // Initialize iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Handle notification responses including action buttons
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Log the response details to debug
        devPrint('NOTIFICATION ACTION RECEIVED: ${details.actionId}');
        devPrint('NOTIFICATION PAYLOAD RECEIVED: ${details.payload}');
        
        // Pass to the handler
        _handleNotificationResponse(details);
      },
    );
    
    // For Android 13+, we need to explicitly check notification permissions
    // but for older versions, we don't need to request permissions
    // so we'll just log the initialization instead
    final AndroidFlutterLocalNotificationsPlugin? androidImpl = 
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      devPrint('Android notification plugin initialized');
    }
    
    // Create notification channel
    await _createNotificationChannel();
    
    // Initialize the medication action service
    await MedicationActionService().initialize();
    
    devPrint('Notification service initialized successfully');
  }

  Future<void> initialize() async {
    await _init();
  }

  /// Handle notification responses, including action buttons
  void _handleNotificationResponse(NotificationResponse response) {
    devPrint('Notification response received: ${response.payload}');
    devPrint('Action ID: ${response.actionId ?? 'NO_ACTION_ID'}');
    
    // Check if we have a payload
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Parse the payload JSON
        final Map<String, dynamic> payload = json.decode(response.payload!);
        
        devPrint('Notification action ID: ${response.actionId}');
        devPrint('Notification payload decoded: $payload');
        
        // Process different action types
        switch (response.actionId) {
          case 'SNOOZE_ACTION':
            devPrint(' SNOOZE button pressed - processing...');
            _handleSnoozeAction(payload);
            break;
          case 'MARK_TAKEN_ACTION':
            devPrint(' MARK AS TAKEN button pressed - processing...');
            _handleMarkTakenAction(payload);
            break;
          default:
            // Handle regular notification tap (no specific action)
            devPrint('Regular notification tapped (no action button), payload: $payload');
        }
      } catch (e) {
        devPrint(' Error handling notification response: $e');
      }
    } else {
      devPrint(' Empty payload in notification response');
    }
  }
  
  /// For testing only - allows tests to simulate notification responses
  Future<void> testHandleNotificationResponse(NotificationResponse response) async {
    // Log that this is a test method
    devPrint('TEST: Simulating notification response');
    _handleNotificationResponse(response);
  }
  
  /// Handle the snooze action
  Future<void> _handleSnoozeAction(Map<String, dynamic> payload) async {
    // Get the notification ID and medication ID
    final String medicationId = payload['medicationId'] ?? '';
    
    if (medicationId.isEmpty) {
      devPrint('❌ Cannot snooze: No medication ID provided in payload');
      return;
    }
    
    try {
      // Get medication data from payload
      final String notificationId = payload['notificationId'] ?? '';
      final String medicationName = payload['medicationName'] ?? 'medication';
      
      devPrint('🔔 Processing snooze for medication: $medicationName (ID: $medicationId)');
      
      // Use the MedicationActionService to snooze this medication
      final success = await MedicationActionService().snoozeMedication(
        medicationId,
        snoozeMinutes: 5, // Snooze for 5 minutes
        metadata: payload, // Include all original payload data
      );
      
      if (success) {
        // Schedule a new notification for 5 minutes from now
        final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
        
        // Create a notification title and body with medication information
        final String title = 'Snoozed: Take your $medicationName';
        final String body = 'This is a snoozed reminder for your medication';
        
        // Add information to payload to indicate this is a snoozed notification
        final Map<String, dynamic> updatedPayload = Map<String, dynamic>.from(payload);
        updatedPayload['isSnoozed'] = true;
        updatedPayload['originalNotificationId'] = notificationId;
        updatedPayload['snoozeTime'] = snoozeTime.toIso8601String();
        
        // Use a consistent ID for the snoozed notification based on the original
        final int snoozeNotificationId = notificationId.isNotEmpty 
            ? int.parse(notificationId) + 1000 // Derived from original ID
            : DateTime.now().millisecondsSinceEpoch % 100000000; // Fallback
        
        // Schedule the snoozed notification
        await showNotification(
          snoozeNotificationId,
          title,
          body,
          payload: updatedPayload,
          includeSnoozeAction: true, // Allow re-snoozing
        );
        
        devPrint('✅ Medication $medicationId snoozed until $snoozeTime');
      } else {
        devPrint('❌ Failed to snooze medication $medicationId');
      }
    } catch (e) {
      devPrint('❌ Error handling snooze action: $e');
    }
  }
  
  /// Handle the mark as taken action
  Future<void> _handleMarkTakenAction(Map<String, dynamic> payload) async {
    // Get the medication ID
    final String medicationId = payload['medicationId'] ?? '';
    
    if (medicationId.isEmpty) {
      devPrint('❌ Cannot mark medication as taken: No medication ID provided');
      return;
    }
    
    try {
      // Get medication name if available
      final String medicationName = payload['medicationName'] ?? 'medication';
      
      devPrint('🔔 Processing mark as taken for: $medicationName (ID: $medicationId)');
      
      // Use the MedicationActionService to mark medication as taken
      final success = await MedicationActionService().markMedicationAsTaken(
        medicationId, 
        metadata: payload,
      );
      
      if (success) {
        // Cancel the notification to remove it from the notification drawer
        final String notificationId = payload['notificationId'] ?? '';
        if (notificationId.isNotEmpty) {
          await _notificationsPlugin.cancel(int.parse(notificationId));
          devPrint('Cancelled notification ID: $notificationId');
        }
        
        devPrint('✅ Medication $medicationId marked as taken successfully');
      } else {
        devPrint('❌ Failed to mark medication $medicationId as taken');
      }
    } catch (e) {
      devPrint('❌ Error marking medication as taken: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    // Get the selected sound path
    final selectedSoundPath = await getSelectedSoundPath();

    // Create a notification channel for Android
    AndroidNotificationChannel channel;

    if (selectedSoundPath != null && selectedSoundPath.isNotEmpty) {
      // Use custom sound
      devPrint('Using custom notification sound: $selectedSoundPath');

      // For custom sounds, we need to use a RawResourceAndroidNotificationSound
      // The sound file should be in the raw resource folder
      // For asset sounds, we'll use the default sound for now
      // In a production app, you would copy the asset to the raw resource folder
      channel = const AndroidNotificationChannel(
        'pill_channel_id', // Channel ID
        'Pill Reminders', // Channel name
        description: 'Reminders for taking your pills',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: RawResourceAndroidNotificationSound(
            'pill_alarm'), // Use custom sound
      );
    } else {
      // Use default sound
      devPrint('Using default notification sound');
      channel = const AndroidNotificationChannel(
        'pill_channel_id', // Channel ID
        'Pill Reminders', // Channel name
        description: 'Reminders for taking your pills',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: null, // Use default sound
      );
    }

    // Create the channel
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    devPrint('Created notification channel');
  }

  // Show an immediate notification for testing
  Future<void> showImmediateNotification() async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pill_channel_id',
      'Pill Reminders',
      channelDescription: 'Reminders for taking your pills',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification',
      platformChannelSpecifics,
      payload: 'test',
    );

    devPrint('Showed immediate notification');
  }

  /// Show a notification with optional payload and snooze action
  Future<void> showNotification(
    int id,
    String title,
    String body, {
    Map<String, dynamic>? payload,
    bool includeSnoozeAction = true,
  }) async {
    // Get the selected sound
    final selectedSoundPath = await getSelectedSoundPath();
    
    // Create Android notification details with actions
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pill_channel_id',
      'Pill Reminders',
      channelDescription: 'Reminders for taking your pills',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(selectedSoundPath ?? 'default'),
      // Include action buttons for the notification
      actions: includeSnoozeAction ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'SNOOZE_ACTION',
          'Snooze',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'MARK_TAKEN_ACTION',
          'Mark as Taken',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ] : null,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Convert payload to string if provided
    final String? payloadStr = payload != null ? json.encode(payload) : null;
    
    // Show the notification
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payloadStr,
    );
    
    devPrint('Showed notification with ID: $id, Title: $title, Payload: $payloadStr');
  }

  /// Schedule a pill reminder notification
  Future<void> schedulePillReminder(
    int id,
    String title,
    String body,
    DateTime scheduledTime, {
    Map<String, dynamic>? payload,
    bool includeSnoozeAction = true,
  }) async {
    // Get the selected sound
    final selectedSoundPath = await getSelectedSoundPath();
    devPrint('Using custom notification sound for reminder: $selectedSoundPath');

    // Create notification details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pill_channel_id',
      'Pill Reminders',
      channelDescription: 'Reminders for taking your pills',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(selectedSoundPath ?? 'default'),
      additionalFlags: Int32List.fromList(<int>[4]), // Insistent flag for Android
      // Add actions for the notification
      actions: includeSnoozeAction ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'SNOOZE_ACTION',
          'Snooze',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'MARK_TAKEN_ACTION',
          'Mark as Taken',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ] : null,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Ensure we include notificationId in the payload for action handling
    if (payload != null) {
      payload['notificationId'] = id.toString();
    }
    
    // Convert payload to string
    final String? payloadStr = payload != null ? json.encode(payload) : null;
    
    // Log full payload for debugging
    devPrint('Scheduling notification with payload: $payloadStr');

    // Convert to TZDateTime
    final tz.TZDateTime zonedTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Schedule the notification
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      zonedTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadStr,
    );

    devPrint('Scheduled pill reminder for $zonedTime');
  }

  /// Schedule a notification at a specific time using timezone
  Future<void> zonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    String? payload,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    try {
      // Try to schedule with exact timing first
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      devPrint('Scheduled notification for: $scheduledDate');
    } catch (e) {
      // If exact alarms are not permitted, fall back to inexact alarms
      if (e.toString().contains('exact_alarms_not_permitted')) {
        devPrint('Exact alarms not permitted, falling back to inexact alarms');

        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
        devPrint('Scheduled inexact notification for: $scheduledDate');
      } else {
        // For other errors, rethrow
        devPrint('Error scheduling notification: $e');
        rethrow;
      }
    }
  }

  // Cancel a specific reminder
  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }
    return false;
  }
}

// Usage example
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationTestScreen(notificationService: notificationService),
    );
  }
}

class NotificationTestScreen extends StatefulWidget {
  final NotificationService notificationService;

  const NotificationTestScreen({super.key, required this.notificationService});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String _status = 'Tap a button to test notifications';

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final enabled = await widget.notificationService.areNotificationsEnabled();
    setState(() {
      _status = enabled
          ? 'Notifications are enabled'
          : 'Notifications are disabled. Please enable them in settings.';
    });
  }

  void _updateStatus(String message) {
    setState(() {
      _status = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pill Reminder Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.notificationService.showImmediateNotification();
                _updateStatus(
                    'Immediate notification sent! Check your notification tray.');
              },
              child: const Text('Test Immediate Notification'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final scheduledTime = now.add(const Duration(seconds: 5));
                widget.notificationService.schedulePillReminder(
                  1,
                  'Pill Time!',
                  'Take your morning pill now.',
                  scheduledTime,
                );
                _updateStatus(
                    'Scheduled notification for 5 seconds from now: ${scheduledTime.toString()}');
              },
              child: const Text('Set 5-Second Reminder'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkNotificationStatus,
              child: const Text('Check Notification Status'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Note: On emulators, you may need to pull down the notification shade to see notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
