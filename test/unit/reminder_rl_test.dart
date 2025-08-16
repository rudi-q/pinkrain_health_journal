import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/features/treatment/domain/reminder_rl.dart';

void main() {
  group('ReminderRL', () {
    late ReminderRL reminderRL;
    late List<DateTime> timeSlots;

    setUp(() {
      timeSlots = [
        DateTime(2023, 1, 1, 8, 0), // 8:00 AM
        DateTime(2023, 1, 1, 12, 0), // 12:00 PM
        DateTime(2023, 1, 1, 18, 0), // 6:00 PM
      ];
      reminderRL = ReminderRL(timeSlots);
    });

    test('ReminderRL initializes correctly', () {
      expect(reminderRL.timeSlots, equals(timeSlots));
      expect(reminderRL.successes.length, equals(3));
      expect(reminderRL.failures.length, equals(3));
      for (var time in timeSlots) {
        expect(reminderRL.successes[time], equals(0));
        expect(reminderRL.failures[time], equals(0));
      }
    });

    test('selectBestReminder returns a valid time slot', () {
      final bestReminder = reminderRL.selectBestReminder();
      expect(timeSlots.contains(bestReminder), isTrue);
    });

    test('updateResults increases success count', () {
      final selectedTime = timeSlots[0];
      reminderRL.updateResults(selectedTime, true);
      expect(reminderRL.successes[selectedTime], equals(1));
      expect(reminderRL.failures[selectedTime], equals(0));
    });

    test('updateResults increases failure count', () {
      final selectedTime = timeSlots[1];
      reminderRL.updateResults(selectedTime, false);
      expect(reminderRL.successes[selectedTime], equals(0));
      expect(reminderRL.failures[selectedTime], equals(1));
    });

    test('updateResults adds new time slot if not present', () {
      final newTime = DateTime(2023, 1, 1, 22, 0); // 10:00 PM
      reminderRL.updateResults(newTime, true);
      expect(reminderRL.timeSlots.contains(newTime), isTrue);
      expect(reminderRL.successes[newTime], equals(1));
      expect(reminderRL.failures[newTime], equals(0));
    });

    test('selectBestReminder favors successful time slots over time', () {
      final favoredTime = timeSlots.last;
      for (int i = 0; i < 10; i++) {
        reminderRL.updateResults(favoredTime, true);
      }

      int favoredCount = 0;
      int totalTrials = 100;
      for (int i = 0; i < totalTrials; i++) {
        if (reminderRL.selectBestReminder() == favoredTime) {
          favoredCount++;
        }
      }

      // The favored time should be selected more often than not
      expect(favoredCount, greaterThan(totalTrials ~/ 2));
    });

    /*  test('_betaSample returns a value between 0 and 1', () {
      for (int i = 0; i < 100; i++) {
        double sample = reminderRL._betaSample(1, 1);
        expect(sample, greaterThanOrEqualTo(0));
        expect(sample, lessThanOrEqualTo(1));
      }
    });

    test('_gammaSample returns a positive value', () {
      for (int i = 1; i <= 10; i++) {
        double sample = reminderRL._gammaSample(i);
        expect(sample, greaterThan(0));
      }
    });*/
  });
}
