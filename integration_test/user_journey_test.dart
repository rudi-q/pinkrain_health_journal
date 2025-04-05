import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pillow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Import your screen widgets
import 'package:pillow/features/journal/presentation/journal_screen.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_screen.dart';
import 'package:pillow/features/wellness/presentation/wellness_screen.dart'
    show WellnessTrackerScreen;
import 'package:pillow/core/services/hive_service.dart';

// Import your components
import 'package:pillow/features/journal/presentation/medication_notification_widget.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Setup test environment
  setUp(() async {
    // Initialize Hive for testing
    final tempDir = await getTemporaryDirectory();
    final testPath = '${tempDir.path}/hive_test';
    await Directory(testPath).create(recursive: true);
    await Hive.initFlutter(testPath);

    // Initialize all required boxes
    await Hive.openBox(HiveService.userPrefsBox);
    await Hive.openBox(HiveService.moodBoxName);
    await Hive.openBox(HiveService.symptomBoxName);
    await Hive.openBox(HiveService.medicationLogsBoxName);
    await Hive.openBox(HiveService.treatmentsBoxName);
  });

  // Cleanup after tests
  tearDown(() async {
    // Close all boxes
    await Hive.close();
    final tempDir = await getTemporaryDirectory();
    final testPath = '${tempDir.path}/hive_test';
    await Directory(testPath).delete(recursive: true);
  });

  group('End-to-End User Journey Test', () {
    testWidgets('Complete user flow test', (tester) async {
      // Configure for visual testing
      await tester.binding.setSurfaceSize(const Size(400, 800));

      // Launch app wrapped in ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          child: const MyApp(),
        ),
      );

      // Wait for app to settle and any initial animations to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Part 1: Initial Journal Screen Verification
      expect(find.byType(JournalScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Handle mood prompt if it appears
      if (find.text('How are you feeling today?').evaluate().isNotEmpty) {
        // Select mood using radio buttons or similar widget
        final moodOptions = find.byType(RadioListTile);
        if (moodOptions.evaluate().isNotEmpty) {
          await tester.tap(moodOptions.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        // Enter mood description
        final textField = find.byType(TextField).first;
        if (textField.evaluate().isNotEmpty) {
          await tester.enterText(textField, 'Feeling good today');
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        // Submit mood
        final submitButton = find.text('Submit');
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // Part 2: Medication Management
      // Look for medication notification widget
      final medWidget = find.byType(MedicationNotificationWidget);
      if (medWidget.evaluate().isNotEmpty) {
        await tester.tap(medWidget.first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        // Add note if text field is present
        final noteField = find.byType(TextField).first;
        if (noteField.evaluate().isNotEmpty) {
          await tester.enterText(noteField, 'Taken with food');
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        // Save if button is present
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // Part 3: Pillbox Navigation & Interaction
      // Navigate to Pillbox using bottom navigation
      final pillboxNav = find.byIcon(Icons.medical_services);
      if (pillboxNav.evaluate().isNotEmpty) {
        await tester.tap(pillboxNav);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Verify Pillbox screen
      expect(find.byType(PillboxScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Add new treatment if button exists
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Interact with form elements that are present
        final durationField = find.byType(DropdownButtonFormField).first;
        if (durationField.evaluate().isNotEmpty) {
          await tester.tap(durationField);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        // Look for save button
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // Part 4: Wellness Screen Navigation & Interaction
      final wellnessNav = find.byIcon(Icons.insights);
      if (wellnessNav.evaluate().isNotEmpty) {
        await tester.tap(wellnessNav);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Verify Wellness screen
      expect(find.byType(WellnessTrackerScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Test time period switches if they exist
      for (final period in ['Daily', 'Weekly', 'Monthly']) {
        final periodTab = find.text(period);
        if (periodTab.evaluate().isNotEmpty) {
          await tester.tap(periodTab);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // Part 5: Return to Journal
      // Navigate back to Journal
      final journalNav = find.byIcon(Icons.book);
      if (journalNav.evaluate().isNotEmpty) {
        await tester.tap(journalNav);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Verify we're back on Journal screen
      expect(find.byType(JournalScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    });
  });
}
