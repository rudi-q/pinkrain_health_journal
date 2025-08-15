import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'test_wellness_screen.dart';

void main() {
  group('TestWellnessScreen', () {
    testWidgets('should display the current date', (WidgetTester tester) async {
      // Arrange
      final today = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: TestWellnessScreen(initialDate: today),
        ),
      );

      // Assert
      final formattedDate = DateFormat('MMMM yyyy').format(today);
      expect(find.text(formattedDate), findsOneWidget);
    });

    testWidgets('should navigate to previous day when left arrow is tapped',
        (WidgetTester tester) async {
      // Arrange
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: TestWellnessScreen(initialDate: today),
        ),
      );

      // Act - tap the left arrow
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Assert - should show yesterday's date
      final formattedYesterday = DateFormat('dd/MM/yyyy').format(yesterday);
      expect(find.textContaining(formattedYesterday), findsOneWidget);
    });

    testWidgets('should navigate to today when Today button is tapped',
        (WidgetTester tester) async {
      // Arrange - use a past date
      final pastDate = DateTime.now().subtract(const Duration(days: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: TestWellnessScreen(initialDate: pastDate),
        ),
      );

      // Act - tap the Today button
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Assert - should show today's date
      final today = DateTime.now();
      final formattedToday = DateFormat('dd/MM/yyyy').format(today);
      expect(find.textContaining(formattedToday), findsOneWidget);
    });

    testWidgets('should disable next navigation button when date is today',
        (WidgetTester tester) async {
      // Arrange - use today's date
      final today = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: TestWellnessScreen(initialDate: today),
        ),
      );
      await tester.pumpAndSettle();

      // Find the next button
      final nextButtonFinder = find.byKey(const Key('nextButton'));

      // Get the IconButton widget
      final IconButton iconButton = tester.widget<IconButton>(nextButtonFinder);

      // Verify that the onPressed callback is null (button is disabled)
      expect(iconButton.onPressed, isNull);

      // Verify the text indicating navigation is not possible
      expect(find.text('Can navigate next: false'), findsOneWidget);
    });

    testWidgets('should enable next navigation button when date is in the past',
        (WidgetTester tester) async {
      // Arrange - use a past date
      final pastDate = DateTime.now().subtract(const Duration(days: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: TestWellnessScreen(initialDate: pastDate),
        ),
      );
      await tester.pumpAndSettle();

      // Find the next button
      final nextButtonFinder = find.byKey(const Key('nextButton'));

      // Get the IconButton widget
      final IconButton iconButton = tester.widget<IconButton>(nextButtonFinder);

      // Verify that the onPressed callback is not null (button is enabled)
      expect(iconButton.onPressed, isNotNull);

      // Verify the text indicating navigation is possible
      expect(find.text('Can navigate next: true'), findsOneWidget);
    });
  });
}
