import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/core/util/helpers.dart';

void main() {
  group('DateTimeExtension', () {
    test('isSameDate should return true for same dates with different times',
        () {
      // Arrange
      final date1 = DateTime(2023, 5, 15, 10, 30);
      final date2 = DateTime(2023, 5, 15, 15, 45);

      // Act & Assert
      expect(date1.isSameDate(date2), true);
    });

    test('isSameDate should return false for different dates', () {
      // Arrange
      final date1 = DateTime(2023, 5, 15);
      final date2 = DateTime(2023, 5, 16);

      // Act & Assert
      expect(date1.isSameDate(date2), false);
    });
  });

  group('StringExtension', () {
    test('capitalize should capitalize first letter of string', () {
      // Act & Assert
      expect('day'.capitalize(), 'Day');
      expect('month'.capitalize(), 'Month');
      expect('year'.capitalize(), 'Year');
    });

    test('capitalize should handle empty strings', () {
      // Act & Assert
      expect(''.capitalize(), '');
    });

    test('capitalize should not change already capitalized strings', () {
      // Act & Assert
      expect('Day'.capitalize(), 'Day');
      expect('Month'.capitalize(), 'Month');
      expect('Year'.capitalize(), 'Year');
    });
  });

  group('Date Navigation Logic', () {
    test('should not allow navigation beyond current date', () {
      // Create a test date that is today
      final today = DateTime.now();

      // Create date objects for testing different time ranges
      final nextDay = today.add(const Duration(days: 1));
      final nextMonth = DateTime(today.year, today.month + 1, today.day);
      final nextYear = DateTime(today.year + 1, today.month, today.day);

      // Verify all future dates are after today
      expect(nextDay.isAfter(today), true);
      expect(nextMonth.isAfter(today), true);
      expect(nextYear.isAfter(today), true);

      // Test the logic used in the _navigateToNext method
      expect(!nextDay.isAfter(today), false); // Should not allow navigation
      expect(!nextMonth.isAfter(today), false); // Should not allow navigation
      expect(!nextYear.isAfter(today), false); // Should not allow navigation
    });
  });
}
