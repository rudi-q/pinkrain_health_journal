import 'package:pillow/core/util/helpers.dart';

import '../domain/reminder_rl.dart';

class TreatmentPlan {
  DateTime startDate;
  DateTime endDate;
  DateTime timeOfDay = DateTime(2023, 1, 1, 11, 0);
  final String mealOption;
  final String instructions;
  final Duration frequency;
  ReminderRL reminderRL = ReminderRL([]);

  TreatmentPlan({
    required this.startDate,
    required this.endDate,
    required this.timeOfDay,
    this.mealOption = '',
    this.instructions = '',
    this.frequency = const Duration(days: 1)
  });

  bool isOnGoing() {
    return startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
  }

  String intakeFrequency() {
    final String freq = frequency.inDays <= 1
        ? '${24 / frequency.inHours} times a day'
        : 'Every ${frequency.inDays} days';
    return freq;
  }

  int requiredPills(int currentMedicationAmount) {
    'Current medication amount: $currentMedicationAmount'.log();
    Duration remainingPeriod = endDate.difference(DateTime.now());
    'Remaining period: ${remainingPeriod.inDays} days'.log();
    final double requiredPills =
        (remainingPeriod.inHours / frequency.inHours) - currentMedicationAmount;
    return requiredPills.toInt();
  }

  String pillStatus(int currentMedicationAmount) {
    final requiredNumber = requiredPills(currentMedicationAmount);
    return requiredNumber < 1
        ? 'Extra pills: $requiredNumber'
        : 'Pills needed: $requiredNumber';
  }
}
