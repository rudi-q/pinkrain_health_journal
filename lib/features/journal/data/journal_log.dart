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
      medicationLogs[date]!.addAll(Treatment.getSample().map((treatment) => IntakeLog(treatment)));
    }
    return medicationLogs[date] ?? [];
  }
}