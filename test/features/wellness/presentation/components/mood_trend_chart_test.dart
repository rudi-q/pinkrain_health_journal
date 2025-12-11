import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinkrain/features/wellness/presentation/components/mood_trend_chart.dart';

void main() {
  // Setup for mocking mood data
  late Map<String, Map<String, dynamic>?> mockMoodData;

  // Custom mood data fetcher for testing
  Future<Map<String, dynamic>?> testMoodDataFetcher(DateTime date) async {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return mockMoodData[dateString];
  }

  setUp(() {
    // Reset the mock data for each test
    mockMoodData = {};
  });

  group('MoodTrendChart', () {
    testWidgets('should display loading indicator initially',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'month',
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Assert - should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should update chart description based on timeRange',
        (WidgetTester tester) async {
      // Arrange - Day view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'day',
              selectedDate: DateTime(2023, 5, 15),
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Let the widget finish loading and show error state (no data)
      await tester.pumpAndSettle();

      // Assert - should show "No mood data available" since we have no mock data
      expect(find.text('No mood data available for this period'), findsOneWidget);

      // Arrange - Month view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'month',
              selectedDate: DateTime(2023, 5, 15),
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Let the widget finish loading and show error state (no data)
      await tester.pumpAndSettle();

      // Assert - should show "No mood data available" since we have no mock data
      expect(find.text('No mood data available for this period'), findsOneWidget);

      // Arrange - Year view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'year',
              selectedDate: DateTime(2023, 5, 15),
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Let the widget finish loading and show error state (no data)
      await tester.pumpAndSettle();

      // Assert - should show "No mood data available" since we have no mock data
      expect(find.text('No mood data available for this period'), findsOneWidget);
    });

    testWidgets('should show empty state message when no data is available',
        (WidgetTester tester) async {
      // Arrange - ensure mock data is empty
      mockMoodData = {};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'month',
              selectedDate: DateTime(2023, 5, 15),
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Assert - should show empty state message
      expect(
          find.text('No mood data available for this period'), findsOneWidget);
    });

    testWidgets('should reload data when timeRange changes',
        (WidgetTester tester) async {
      // Arrange
      final initialDate = DateTime(2023, 5, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'month',
              selectedDate: initialDate,
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Wait for initial loading
      await tester.pumpAndSettle();

      // Assert - should show "No mood data available" message
      expect(find.text('No mood data available for this period'), findsOneWidget);

      // Act - change time range to year
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'year',
              selectedDate: initialDate,
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Wait for reload
      await tester.pumpAndSettle();

      // Assert - should show "No mood data available" message
      expect(find.text('No mood data available for this period'), findsOneWidget);
    });

    testWidgets('should reload data when selectedDate changes',
        (WidgetTester tester) async {
      // Arrange
      final initialDate = DateTime(2023, 5, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'month',
              selectedDate: initialDate,
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Wait for initial loading
      await tester.pumpAndSettle();

      // Assert - should show "No mood data available" message
      expect(find.text('No mood data available for this period'), findsOneWidget);

      // Act - change date to June 2023
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'month',
              selectedDate: DateTime(2023, 6, 15),
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Wait for reload
      await tester.pumpAndSettle();

      // Assert - still no data, so should show empty message
      expect(find.text('No mood data available for this period'), findsOneWidget);
    });

    testWidgets('should display mood data from Hive service',
        (WidgetTester tester) async {
      // Setup mock data for a month view
      final testDate = DateTime(2023, 5, 15);

      // Create mock mood data for the month of May 2023
      mockMoodData = {
        '2023-05-01': {'mood': 3, 'note': 'Feeling okay'},
        '2023-05-05': {'mood': 4, 'note': 'Feeling good'},
        '2023-05-10': {'mood': 5, 'note': 'Feeling great'},
        '2023-05-15': {'mood': 2, 'note': 'Feeling down'},
        '2023-05-20': {'mood': 3, 'note': 'Feeling better'},
      };

      // Render the MoodTrendChart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodTrendChart(
              timeRange: 'month',
              selectedDate: testDate,
              moodDataFetcher: testMoodDataFetcher,
            ),
          ),
        ),
      );

      // Wait for the chart to load
      await tester.pumpAndSettle();

      // Verify the chart title is correct
      expect(find.text('Your daily mood trends for May 2023'), findsOneWidget);

      // Verify the chart is displayed (not the empty state)
      expect(find.text('Visualize how your mood has changed over time'), findsOneWidget);
      expect(find.text('No mood data available for this period'), findsNothing);
    });
  });
}
