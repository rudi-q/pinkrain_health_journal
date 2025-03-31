import 'package:pillow/core/util/helpers.dart';

import '../../treatment/domain/treatment_manager.dart';

class IntakeLog {
  late Treatment treatment;
  late bool isTaken = false;

  IntakeLog(this.treatment);
}

class JournalLog {
  late Map<DateTime, List<IntakeLog>> medicationLogs;

  JournalLog() {
    medicationLogs = {};
  }

  List<IntakeLog> getMedicationsForTheDay(DateTime date) {
    date = date.normalize();
    medicationLogs[date] = medicationLogs[date] ?? [];
    if (medicationLogs[date]!.isEmpty) {
      medicationLogs[date]!.addAll(
          Treatment.getSample().map((treatment) => IntakeLog(treatment)));
    }
    return medicationLogs[date] ?? [];
  }

  double getAdherenceRate(
      Treatment treatment, DateTime startDate, DateTime endDate) {
    int takenCount = 0;
    int totalDays = 0;

    DateTime currentDate = startDate.normalize();

    while (!currentDate.isAfter(endDate)) {
      if (medicationLogs.containsKey(currentDate)) {
        for (var log in medicationLogs[currentDate]!) {
          if (log.treatment.medicine.name == treatment.medicine.name) {
            takenCount += log.isTaken ? 1 : 0;
            totalDays++;
          }
        }
      }
      currentDate = currentDate.add(Duration(days: 1));
    }

    if (totalDays == 0) return 0.0;
    return takenCount / totalDays;
  }
}
