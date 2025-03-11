import 'package:flutter_test/flutter_test.dart';

class TestableNavigationLogic {
  DateTime selectedDate;
  String selectedDateOption;
  
  TestableNavigationLogic({
    required this.selectedDate,
    this.selectedDateOption = 'day',
  });
  
  bool canNavigateNext() {
    final now = DateTime.now();
    final nextDate = switch (selectedDateOption) {
      'day' => selectedDate.add(const Duration(days: 1)),
      'month' => DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          selectedDate.day,
        ),
      'year' => DateTime(
          selectedDate.year + 1,
          selectedDate.month,
          selectedDate.day,
        ),
      _ => selectedDate,
    };
    
    // Only allow navigation up to the current date
    return !nextDate.isAfter(now);
  }
}

void main() {
  group('Navigation Logic', () {
    test('should not allow navigation beyond today in day view', () {
      // Arrange - use today's date
      final today = DateTime.now();
      final logic = TestableNavigationLogic(
        selectedDate: today,
        selectedDateOption: 'day',
      );
      
      // Act & Assert
      expect(logic.canNavigateNext(), false);
    });
    
    test('should not allow navigation beyond today in month view', () {
      // Arrange - use today's date
      final today = DateTime.now();
      final logic = TestableNavigationLogic(
        selectedDate: today,
        selectedDateOption: 'month',
      );
      
      // Act & Assert
      expect(logic.canNavigateNext(), false);
    });
    
    test('should not allow navigation beyond today in year view', () {
      // Arrange - use today's date
      final today = DateTime.now();
      final logic = TestableNavigationLogic(
        selectedDate: today,
        selectedDateOption: 'year',
      );
      
      // Act & Assert
      expect(logic.canNavigateNext(), false);
    });
    
    test('should allow navigation to today from a past date', () {
      // Arrange - use a past date
      final pastDate = DateTime.now().subtract(const Duration(days: 30));
      final logic = TestableNavigationLogic(
        selectedDate: pastDate,
        selectedDateOption: 'day',
      );
      
      // Act & Assert
      expect(logic.canNavigateNext(), true);
    });
  });
}
