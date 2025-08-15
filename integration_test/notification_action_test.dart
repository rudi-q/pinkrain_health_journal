import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/journal/domain/push_notifications.dart';
import 'package:pillow/features/treatment/services/medication_action_service.dart';

/// Integration test for notification actions
/// Tests both the "Snooze" and "Mark as Taken" actions
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Create a minimal app for testing
  Widget createTestApp() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Notification Action Test'),
            ],
          ),
        ),
      ),
    );
  }

  group('Notification Action Tests', () {
    late NotificationService notificationService;
    late MedicationActionService medicationActionService;
    
    setUp(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      
      // Initialize services
      notificationService = NotificationService();
      await notificationService.initialize();
      
      medicationActionService = MedicationActionService();
      await medicationActionService.initialize();
      
      // Clear any existing data
      final box = await Hive.openBox('medication_actions');
      await box.clear();
      
      devPrint('Test setup complete');
    });
    
    tearDown(() async {
      // Clean up after each test
      final box = await Hive.openBox('medication_actions');
      await box.clear();
      await box.close();
    });

    testWidgets('Test notification creation with action buttons', (WidgetTester tester) async {
      // Build our test app
      await tester.pumpWidget(createTestApp());
      
      // Create a test medication ID
      const String testMedicationId = 'test_medication_123';
      const int notificationId = 12345;
      
      // Create a notification with action buttons
      await notificationService.showNotification(
        notificationId,
        'Test Medication Reminder',
        'Time to take your test medication',
        payload: {
          'medicationId': testMedicationId,
          'notificationId': notificationId.toString(),
          'medicationName': 'Test Medication',
        },
        includeSnoozeAction: true,
      );
      
      // Verify the notification was created
      // Note: In a real integration test, you'd need to interact with actual Android notifications
      // which requires device-specific testing. Here we're just verifying our services work.
      
      // Instead, we'll simulate the action response handling
      
      // Create a mock notification response for "Mark as Taken" action
      final NotificationResponse takenResponse = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        payload: '{"medicationId":"$testMedicationId","notificationId":"$notificationId","medicationName":"Test Medication"}',
        actionId: 'MARK_TAKEN_ACTION',
        id: notificationId,
      );
      
      // Manually call the handler method (simulating tapping "Mark as Taken")
      await notificationService.testHandleNotificationResponse(takenResponse);
      
      // Verify medication was marked as taken in the database
      final isTaken = await medicationActionService.isMedicationTaken(testMedicationId);
      expect(isTaken, true, reason: 'Medication should be marked as taken');
      
      // Now test snooze functionality
      
      // Create a mock notification response for "Snooze" action
      final NotificationResponse snoozeResponse = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        payload: '{"medicationId":"$testMedicationId","notificationId":"$notificationId","medicationName":"Test Medication"}',
        actionId: 'SNOOZE_ACTION',
        id: notificationId,
      );
      
      // Clear previous action
      final box = await Hive.openBox('medication_actions');
      await box.clear();
      
      // Manually call the handler method (simulating tapping "Snooze")
      await notificationService.testHandleNotificationResponse(snoozeResponse);
      
      // Verify medication status is now "snoozed"
      final statusMap = await medicationActionService.getMedicationStatus(testMedicationId);
      expect(statusMap['status'], 'snoozed', reason: 'Medication should be marked as snoozed');
      expect(statusMap.containsKey('snoozeUntil'), true, reason: 'Snooze until time should be set');
      
      devPrint('Notification action test completed successfully');
    });
  });
}
