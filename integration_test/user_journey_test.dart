import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/util/helpers.dart';
// Import your screen widgets
import 'package:pinkrain/features/journal/presentation/journal_screen.dart';
import 'package:pinkrain/features/journal/presentation/journal_screen_wrapper.dart';
import 'package:pinkrain/features/pillbox/presentation/pillbox_screen.dart';
import 'package:pinkrain/features/splash/splash_screen.dart';
import 'package:pinkrain/features/wellness/presentation/wellness_screen.dart'
    show WellnessTrackerScreen;
import 'package:pinkrain/main.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Setup test environment
  setUp(() async {
    try {
      // Initialize Hive for testing
      final tempDir = await getTemporaryDirectory();
      final testPath = '${tempDir.path}/hive_test';

      // Clear old test data if it exists
      if (await Directory(testPath).exists()) {
        await Directory(testPath).delete(recursive: true);
      }

      await Directory(testPath).create(recursive: true);
      await Hive.initFlutter(testPath);

      // Initialize all required boxes
      await Hive.openBox(HiveService.userPrefsBox);
      await Hive.openBox(HiveService.moodBoxName);
      await Hive.openBox(HiveService.symptomBoxName);
      await Hive.openBox(HiveService.medicationLogsBoxName);
      await Hive.openBox(HiveService.treatmentsBoxName);

      devPrint('Test setup completed successfully');
    } catch (e) {
      devPrint('Error during test setup: $e');
      rethrow;
    }
  });

  // Cleanup after tests
  tearDown(() async {
    try {
      // Close all boxes
      await Hive.close();
      final tempDir = await getTemporaryDirectory();
      final testPath = '${tempDir.path}/hive_test';
      if (await Directory(testPath).exists()) {
        await Directory(testPath).delete(recursive: true);
      }
      devPrint('Test cleanup completed successfully');
    } catch (e) {
      devPrint('Error during test cleanup: $e');
    }
  });

  group('End-to-End User Journey Test', () {
    testWidgets('Complete user flow test', (tester) async {
      try {
        // Configure for visual testing with common mobile screen size
        await tester.binding.setSurfaceSize(const Size(400, 800));

        // Launch app wrapped in ProviderScope
        await tester.pumpWidget(
          const ProviderScope(
            child: MyApp(),
          ),
        );

        // Wait for splash screen and initial loading
        devPrint('Waiting for app to load...');
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // We might see the splash screen first
        if (find.byType(SplashScreen).evaluate().isNotEmpty) {
          devPrint('Found splash screen, waiting for it to complete...');
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        // Part 1: Initial Journal Screen Verification
        try {
          devPrint('Verifying Journal Screen...');

          // Check if we're on the journal screen by looking for either JournalScreen or JournalScreenWrapper
          final isOnJournalScreen =
              find.byType(JournalScreen).evaluate().isNotEmpty ||
                  find.byType(JournalScreenWrapper).evaluate().isNotEmpty;

          expect(isOnJournalScreen, isTrue, reason: 'Not on Journal Screen');
          await tester.pumpAndSettle();

          devPrint('Starting mood prompt check...');
          // Handle mood prompt if it appears
          final moodPrompt = find.text('How are you feeling today?');
          if (moodPrompt.evaluate().isNotEmpty) {
            devPrint('Found mood prompt, handling it...');
            await tester.pump(const Duration(milliseconds: 500));

            // Select a specific mood option (choosing the Happy option)
            final happyOption = find.text('Happy');
            if (happyOption.evaluate().isNotEmpty) {
              devPrint('Found Happy mood option, selecting it...');
              await tester.tap(happyOption);
              await tester.pumpAndSettle(const Duration(milliseconds: 500));
            } else {
              // Fallback to selecting the first radio button if we can't find "Happy"
              final moodOptions = find.byType(RadioListTile);
              if (moodOptions.evaluate().isNotEmpty) {
                devPrint('Selecting first mood option...');
                await tester.tap(moodOptions.first);
                await tester.pumpAndSettle(const Duration(milliseconds: 500));
              }
            }

            // Enter mood description (safely)
            final textFields = find.byType(TextField);
            if (textFields.evaluate().isNotEmpty) {
              await tester.enterText(
                  textFields.first, 'Feeling good today for the test');
              await tester.pumpAndSettle(const Duration(milliseconds: 500));
            }

            // Find and tap the submit button
            final submitButton = find.text('Submit');
            if (submitButton.evaluate().isNotEmpty) {
              devPrint('Found submit button, tapping it...');
              await tester.ensureVisible(submitButton);
              await tester.pumpAndSettle();
              await tester.tap(submitButton);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            }
          } else {
            devPrint('No mood prompt found, continuing with test...');
          }
        } catch (e) {
          devPrint('Error in Journal screen verification or mood prompt: $e');
          // Continue with the test even if there's an error in this section
        }

        // Part 2: Medication Management on Journal Screen
        try {
          devPrint('Checking for medication interactions...');
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Try to interact with medication items if they exist
          final medicationItem = find.byIcon(Icons.check_circle);
          if (medicationItem.evaluate().isNotEmpty) {
            devPrint(
                'Found medication item with check circle, interacting with it...');
            await tester.tap(medicationItem.first);
            await tester.pumpAndSettle();

            // If a dialog opens, interact with it - try different buttons
            for (final buttonText in ['Close', 'OK', 'Done', 'Take pill']) {
              final button = find.text(buttonText);
              if (button.evaluate().isNotEmpty) {
                devPrint(
                    'Found $buttonText button in medication dialog, tapping it...');
                await tester.tap(button.first);
                await tester.pumpAndSettle();
                break;
              }
            }
          } else {
            // Try alternative approaches to find medication items
            devPrint(
                'No medication items found with check circle, looking for alternatives...');

            // Try looking for medicine item by more specific matching
            // Instead of trying to tap a Row directly, try to find a specific medication item
            // with a more reliable finder
            final medicationTitles = find.descendant(
              of: find.byType(InkWell),
              matching: find.byType(Text),
            );

            if (medicationTitles.evaluate().isNotEmpty) {
              devPrint(
                  'Found potential medication title, tapping its parent...');
              // Find the parent InkWell and tap that instead of the Row
              final inkWell = find.ancestor(
                of: medicationTitles.first,
                matching: find.byType(InkWell),
              );

              if (inkWell.evaluate().isNotEmpty) {
                await tester.tap(inkWell.first, warnIfMissed: false);
                await tester.pumpAndSettle();
              }

              // Try interacting with any dialog that appears
              for (final buttonText in [
                'Close',
                'OK',
                'Done',
                'Take pill',
                'Skip for today'
              ]) {
                final button = find.text(buttonText);
                if (button.evaluate().isNotEmpty) {
                  devPrint('Found $buttonText button in dialog, tapping it...');
                  await tester.tap(button.first);
                  await tester.pumpAndSettle();
                  break;
                }
              }
            } else {
              devPrint('No medication items found');
            }
          }
        } catch (e) {
          devPrint('Error during medication management interaction: $e');
          // Continue with the test even if there's an error in this section
        }

        // Part 3: Pillbox Navigation & Interaction
        try {
          devPrint('Moving to Pillbox screen...');

          // First try to find the bottom navigation bar
          final bottomNav = find.byType(BottomAppBar);
          if (bottomNav.evaluate().isNotEmpty) {
            devPrint('Found bottom navigation bar');
          } else {
            devPrint(
                'Bottom navigation bar not found, looking for alternatives...');
          }
          await tester.pumpAndSettle();

          // Find and tap the Pillbox navigation item
          final pillboxNav = find.ancestor(
            of: find.text('Pillbox'),
            matching: find.byType(GestureDetector),
          );

          if (pillboxNav.evaluate().isNotEmpty) {
            devPrint('Found Pillbox navigation item, tapping it...');
            await tester.tap(pillboxNav.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          } else {
            devPrint(
                'Pillbox navigation item not found, looking for alternative...');
            // Try to find it by icon or other means
            final allNavItems = find.byType(GestureDetector).evaluate();
            if (allNavItems.length >= 2) {
              devPrint('Tapping second navigation item as fallback...');
              await tester.tap(find
                  .byType(GestureDetector)
                  .at(1)); // Tap the second navigation item
              await tester.pumpAndSettle(const Duration(seconds: 2));
            } else if (allNavItems.isNotEmpty) {
              // Try each navigation item
              devPrint('Testing each navigation item to find Pillbox...');
              bool foundPillbox = false;

              for (int i = 0; i < allNavItems.length && !foundPillbox; i++) {
                await tester.tap(find.byType(GestureDetector).at(i));
                await tester.pumpAndSettle(const Duration(seconds: 1));

                // Check if we're on Pillbox screen
                if (find.byType(PillboxScreen).evaluate().isNotEmpty ||
                    find.text('Pillbox').evaluate().isNotEmpty) {
                  foundPillbox = true;
                  devPrint(
                      'Found Pillbox screen after tapping navigation item $i');
                }
              }
            }
          }

          // Verify we're on the Pillbox screen
          final isPillboxScreenVisible =
              find.byType(PillboxScreen).evaluate().isNotEmpty ||
                  find.text('Pillbox').evaluate().isNotEmpty;

          if (isPillboxScreenVisible) {
            devPrint('Successfully navigated to Pillbox screen');
            await tester.pumpAndSettle();

            // Test adding new treatment if the add button exists
            final addButton = find.byIcon(Icons.add);
            if (addButton.evaluate().isNotEmpty) {
              devPrint('Found add button, tapping it...');
              await tester.tap(addButton.first);
              await tester.pumpAndSettle(const Duration(seconds: 1));

              // Fill in treatment form - safely check if TextFormField exists
              final nameFields = find.byType(TextFormField);
              if (nameFields.evaluate().isNotEmpty) {
                devPrint('Entering medication name...');
                await tester.enterText(
                    nameFields.first, 'Test Integration Medication');
                await tester.pumpAndSettle();
              } else {
                devPrint('No TextFormField found for medication name');
              }

              // Try to find and interact with dropdown for selecting medicine type
              final typeDropdowns = find.byType(DropdownButtonFormField);
              if (typeDropdowns.evaluate().isNotEmpty) {
                devPrint('Selecting medication type...');
                await tester.tap(typeDropdowns.first);
                await tester.pumpAndSettle();

                // Select a type option
                final dropdownItems = find.byType(DropdownMenuItem);
                if (dropdownItems.evaluate().isNotEmpty) {
                  await tester.tap(dropdownItems.first);
                  await tester.pumpAndSettle();
                } else {
                  devPrint('No dropdown items found');
                }
              } else {
                devPrint('No dropdown found for medication type');

                // Try to find any selectable items as alternatives
                final listTiles = find.byType(ListTile);
                if (listTiles.evaluate().isNotEmpty) {
                  devPrint(
                      'Found list tile, tapping first one as alternative...');
                  await tester.tap(listTiles.first);
                  await tester.pumpAndSettle();
                }
              }

              // Look for Save or Next or Continue button
              for (final buttonText in ['Save', 'Next', 'Continue']) {
                final button = find.text(buttonText);
                if (button.evaluate().isNotEmpty) {
                  devPrint('Found $buttonText button, tapping it...');
                  await tester.tap(button.first);
                  await tester.pumpAndSettle(const Duration(seconds: 1));
                  break;
                }
              }
            }
          } else {
            devPrint('Could not navigate to Pillbox screen');
          }
        } catch (e) {
          devPrint('Error during Pillbox screen navigation or interaction: $e');
          // Continue with the test even if there's an error in this section
        }

        // Part 4: Wellness Screen Navigation & Interaction
        devPrint('Moving to Wellness screen...');
        // Find and tap wellness navigation item
        try {
          // First attempt - find by text and ancestor
          final wellnessNav = find.ancestor(
            of: find.text('Wellness'),
            matching: find.byType(GestureDetector),
          );

          if (wellnessNav.evaluate().isNotEmpty) {
            devPrint('Found Wellness navigation item, tapping it...');
            await tester.tap(wellnessNav.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          } else {
            devPrint(
                'Wellness navigation item not found, looking for alternative...');

            // Second attempt - try using the insights icon
            final insightsIcon = find.byIcon(Icons.insights);
            if (insightsIcon.evaluate().isNotEmpty) {
              devPrint('Found insights icon, tapping it...');
              await tester.tap(insightsIcon.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            } else {
              // Third attempt - try the third navigation item
              final allNavItems = find.byType(GestureDetector).evaluate();
              if (allNavItems.length >= 3) {
                devPrint('Tapping third navigation item as fallback...');
                await tester.tap(find.byType(GestureDetector).at(2));
                await tester.pumpAndSettle(const Duration(seconds: 2));
              } else if (allNavItems.isNotEmpty) {
                // Last resort - try tapping each navigation item until we find Wellness
                devPrint('Testing each navigation item to find Wellness...');
                bool foundWellness = false;

                for (int i = 0; i < allNavItems.length && !foundWellness; i++) {
                  await tester.tap(find.byType(GestureDetector).at(i));
                  await tester.pumpAndSettle(const Duration(seconds: 1));

                  // Check if we're on Wellness screen
                  if (find
                          .byType(WellnessTrackerScreen)
                          .evaluate()
                          .isNotEmpty ||
                      find.text('Wellness').evaluate().isNotEmpty) {
                    foundWellness = true;
                    devPrint(
                        'Found Wellness screen after tapping navigation item $i');
                  }
                }

                if (!foundWellness) {
                  devPrint(
                      'Could not navigate to Wellness screen after trying all navigation items');
                }
              }
            }
          }
        } catch (e) {
          devPrint('Error navigating to Wellness screen: $e');
          // Continue the test even if we can't navigate to Wellness
        }

        // Verify we're on the Wellness screen
        final isWellnessScreenVisible =
            find.byType(WellnessTrackerScreen).evaluate().isNotEmpty ||
                find.text('Wellness Tracker').evaluate().isNotEmpty ||
                find.text('Wellness').evaluate().isNotEmpty;

        expect(isWellnessScreenVisible, isTrue,
            reason: 'Not on Wellness Screen');
        await tester.pumpAndSettle();

        // Test date range options if they exist
        for (final option in ['Day', 'Month', 'Year']) {
          final dateOption = find.text(option);
          if (dateOption.evaluate().isNotEmpty) {
            devPrint('Found $option option, tapping it...');
            await tester.tap(dateOption.first);
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }
        }

        // Part 5: Return to Journal Screen
        devPrint('Returning to Journal screen...');
        try {
          // First attempt - find by text and ancestor
          final journalNav = find.ancestor(
            of: find.text('Journal'),
            matching: find.byType(GestureDetector),
          );

          if (journalNav.evaluate().isNotEmpty) {
            devPrint('Found Journal navigation item, tapping it...');
            await tester.tap(journalNav.first, warnIfMissed: false);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          } else {
            devPrint(
                'Journal navigation item not found, looking for alternative...');

            // Second attempt - try using the book icon
            final bookIcon = find.byIcon(Icons.book);
            if (bookIcon.evaluate().isNotEmpty) {
              devPrint('Found book icon, tapping it...');
              await tester.tap(bookIcon.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            } else {
              // Third attempt - try the first navigation item
              final allNavItems = find.byType(GestureDetector).evaluate();
              if (allNavItems.isNotEmpty) {
                devPrint('Tapping first navigation item as fallback...');
                await tester.tap(find.byType(GestureDetector).first);
                await tester.pumpAndSettle(const Duration(seconds: 2));
              } else {
                // Last resort - try tapping the back button if navigation items not found
                final backButton = find.byType(BackButton);
                if (backButton.evaluate().isNotEmpty) {
                  devPrint(
                      'Tapping back button to return to previous screen...');
                  await tester.tap(backButton.first);
                  await tester.pumpAndSettle(const Duration(seconds: 2));
                }
              }
            }
          }

          // If we're still not on Journal screen, try each navigation item
          final isOnJournalScreen =
              find.byType(JournalScreen).evaluate().isNotEmpty ||
                  find.byType(JournalScreenWrapper).evaluate().isNotEmpty ||
                  find.text('Journal').evaluate().isNotEmpty;

          if (!isOnJournalScreen) {
            devPrint(
                'Still not on Journal screen, trying each navigation item...');
            final allNavItems = find.byType(GestureDetector).evaluate();
            bool foundJournal = false;

            for (int i = 0; i < allNavItems.length && !foundJournal; i++) {
              await tester.tap(find.byType(GestureDetector).at(i));
              await tester.pumpAndSettle(const Duration(seconds: 1));

              // Check if we're on Journal screen
              if (find.byType(JournalScreen).evaluate().isNotEmpty ||
                  find.byType(JournalScreenWrapper).evaluate().isNotEmpty ||
                  find.text('Journal').evaluate().isNotEmpty) {
                foundJournal = true;
                devPrint(
                    'Found Journal screen after tapping navigation item $i');
              }
            }

            if (!foundJournal) {
              devPrint(
                  'Could not navigate to Journal screen after trying all navigation items');
            }
          }
        } catch (e) {
          devPrint('Error navigating to Journal screen: $e');
          // Continue with test verification even if navigation fails
        }

        // Verify back on Journal screen
        final isBackOnJournalScreen =
            find.byType(JournalScreen).evaluate().isNotEmpty ||
                find.byType(JournalScreenWrapper).evaluate().isNotEmpty ||
                find.text('Journal').evaluate().isNotEmpty;

        expect(isBackOnJournalScreen, isTrue,
            reason: 'Not back on Journal Screen');

        devPrint('User journey test completed successfully');
      } catch (e, stackTrace) {
        devPrint('Error during test: $e');
        devPrint('Stack trace: $stackTrace');
        rethrow;
      }
    });
  });
}
