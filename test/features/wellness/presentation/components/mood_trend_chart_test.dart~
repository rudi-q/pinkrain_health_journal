import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/features/wellness/presentation/components/mood_trend_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

void main() {
  // Setup for mocking mood data
  late Map<String, Map<String, dynamic>?> mockMoodData;
  
  // Custom mood data fetcher for testing
  Future<Map<String, dynamic>?> testMoodDataFetcher(DateTime date) async {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return mockMoodData[dateString];
  }
  
  setUp(() {
    // Reset the mock data for each test
    mockMoodData = {};
  });

  group('MoodTrendChart', () {
    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
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

    testWidgets('should update chart description based on timeRange', (WidgetTester tester) async {
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
      
      // Let the widget finish loading
      await tester.pump(const Duration(milliseconds: 500));
      
      // Assert - should show day description
      expect(find.text('Your mood for 15/5/2023'), findsOneWidget);
      
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
      
      // Let the widget finish loading
      await tester.pump(const Duration(milliseconds: 500));
      
      // Assert - should show month description
      expect(find.text('Your daily mood trends for May 2023'), findsOneWidget);
      
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
      
      // Let the widget finish loading
      await tester.pump(const Duration(milliseconds: 500));
      
      // Assert - should show year description
      expect(find.text('Your monthly mood trends for 2023'), findsOneWidget);
    });

    testWidgets('should show empty state message when no data is available', (WidgetTester tester) async {
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
      expect(find.text('No mood data available for this period'), findsOneWidget);
    });
    
    testWidgets('should reload data when timeRange changes', (WidgetTester tester) async {
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
      
      // Assert - should show month description
      expect(find.text('Your daily mood trends for May 2023'), findsOneWidget);
      
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
      
      // Assert - should show year description
      expect(find.text('Your monthly mood trends for 2023'), findsOneWidget);
    });
    
    testWidgets('should reload data when selectedDate changes', (WidgetTester tester) async {
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
      
      // Assert - should show May 2023
      expect(find.text('Your daily mood trends for May 2023'), findsOneWidget);
      
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
      
      // Assert - should show June 2023
      expect(find.text('Your daily mood trends for June 2023'), findsOneWidget);
    });
    
    testWidgets('should display mood data from Hive service', (WidgetTester tester) async {
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
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No mood data available for this period'), findsNothing);
    });
  });
}
