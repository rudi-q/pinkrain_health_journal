import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/util/helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Key for storing the selected sound in SharedPreferences
  static const String _selectedSoundKey = 'selected_notification_sound';

  // Get the selected notification sound path from SharedPreferences
  Future<String?> getSelectedSoundPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedSoundKey);
  }

  Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize the plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        devPrint('Notification clicked: ${details.payload}');
      },
    );

    // Create notification channel
    await _createNotificationChannel();

    devPrint('Notification service initialized');
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
        sound: null, // We'll set the sound in the notification details instead
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

    await _notificationsPlugin.show(
      0, // Notification ID
      'Test Notification',
      'This is a test notification with sound.',
      notificationDetails,
      payload: 'test_notification',
    );

    devPrint('Showed immediate notification');
  }

  Future<void> schedulePillReminder(
      int id, String title, String body, DateTime scheduledTime) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    // Get the selected sound path
    final selectedSoundPath = await getSelectedSoundPath();

    // Create notification details based on the selected sound
    AndroidNotificationDetails androidDetails;

    if (selectedSoundPath != null && selectedSoundPath.isNotEmpty) {
      // Use custom sound
      devPrint('Using custom notification sound for reminder: $selectedSoundPath');

      // For custom sounds from assets, we would need to copy the asset to the raw resource folder
      // This is a limitation of the flutter_local_notifications package
      // For now, we'll use the default sound if a custom sound is selected
      androidDetails = AndroidNotificationDetails(
        'pill_channel_id', // Channel ID
        'Pill Reminders', // Channel name
        channelDescription: 'Reminders for taking your pills',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        fullScreenIntent: true, // Make notification appear as full screen alert
        category: AndroidNotificationCategory.alarm, // Treat as alarm
        ticker: 'Pill Reminder', // For accessibility and also appears in status bar
        // In a production app, you would use something like:
        // sound: RawResourceAndroidNotificationSound(soundFileName)
      );
    } else {
      // Use default sound
      androidDetails = AndroidNotificationDetails(
        'pill_channel_id', // Channel ID
        'Pill Reminders', // Channel name
        channelDescription: 'Reminders for taking your pills',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        fullScreenIntent: true, // Make notification appear as full screen alert
        category: AndroidNotificationCategory.alarm, // Treat as alarm
        ticker: 'Pill Reminder', // For accessibility and also appears in status bar
      );
    }

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    try {
      // Calculate the delay in seconds
      final int delayInSeconds =
          scheduledTime.difference(DateTime.now()).inSeconds;

      // Create a proper TZDateTime object for the scheduled time
      // Using now() + duration is more reliable than from()
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(Duration(seconds: delayInSeconds));

      devPrint('Current time: ${DateTime.now()}');
      devPrint('Delay in seconds: $delayInSeconds');
      devPrint('Scheduled for: $scheduledDate');

      // Try to schedule with exact timing first
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'pill_reminder',
      );
      devPrint('Scheduled notification for: $scheduledDate');
    } catch (e) {
      // If exact alarms are not permitted, fall back to inexact alarms
      if (e.toString().contains('exact_alarms_not_permitted')) {
        devPrint('Exact alarms not permitted, falling back to inexact alarms');

        // Calculate the delay in seconds
        final int delayInSeconds =
            scheduledTime.difference(DateTime.now()).inSeconds;

        // Create a proper TZDateTime object for the scheduled time
        final tz.TZDateTime scheduledDate =
            tz.TZDateTime.now(tz.local).add(Duration(seconds: delayInSeconds));

        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'pill_reminder',
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
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final enabled = await widget.notificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
      _status = enabled
          ? 'Notifications are enabled'
          : 'Notifications are disabled. Check system settings.';
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
