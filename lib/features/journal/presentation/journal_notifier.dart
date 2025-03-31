import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:intl/intl.dart'; // Import the intl package for DateFormat

import '../data/journal_log.dart';

class SelectedDateNotifier extends StateNotifier<DateTime> {
  SelectedDateNotifier() : super(DateTime.now().normalize());

  void setDate(DateTime date, WidgetRef ref) {
    state = date.normalize();
    final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
    pillIntakeNotifier.populateJournal(state);
  }
  
}

final selectedDateProvider = StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) => SelectedDateNotifier());

class PillIntakeNotifier extends StateNotifier<List<IntakeLog>> {
  final JournalLog _journalLog = JournalLog();

  PillIntakeNotifier() : super([]) {
    populateJournal(DateTime.now().normalize());
  }

  void populateJournal(DateTime selectedDate) => state = _journalLog.getMedicationsForTheDay(selectedDate);

  void pillTaken(IntakeLog log) {
    log.isTaken = true;
  }
  
  // Getter to access the journal log
  JournalLog get journalLog => _journalLog;

  List<String> getMissedDoseDays() {
    Map<String, int> missedDoseDays = {};
    
    // Use the existing medicationLogs data
    _journalLog.medicationLogs.forEach((date, intakeLogs) {
      String dayOfWeek = DateFormat('EEEE').format(date);
      int missedDoses = intakeLogs.where((log) => !log.isTaken).length;
      if (missedDoses > 0) {
        missedDoseDays.update(dayOfWeek, (count) => count + missedDoses, 
            ifAbsent: () => missedDoses);
      }
    });

    // Get the top 2 days with most missed doses
    var sortedDays = missedDoseDays.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return sortedDays.take(2).map((e) => e.key).toList();
  }
}

final pillIntakeProvider = StateNotifierProvider<PillIntakeNotifier, List<IntakeLog>>((ref) => PillIntakeNotifier());
