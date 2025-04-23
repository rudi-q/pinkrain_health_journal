import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Import the intl package for DateFormat
import 'package:pillow/core/util/helpers.dart';

import '../data/journal_log.dart';

class SelectedDateNotifier extends StateNotifier<DateTime> {
  SelectedDateNotifier() : super(DateTime.now().normalize());

  Future<void> setDate(DateTime date, WidgetRef ref) async {
    state = date.normalize();
    final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
    await pillIntakeNotifier.populateJournal(state);
  }
  
}

final selectedDateProvider = StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) => SelectedDateNotifier());

class PillIntakeNotifier extends StateNotifier<List<IntakeLog>> {
  final JournalLog _journalLog = JournalLog();

  PillIntakeNotifier() : super([]) {
    // Initialize with empty state, then populate asynchronously
    _initJournal();
  }
  
  Future<void> _initJournal() async {
    await populateJournal(DateTime.now().normalize());
  }

  Future<void> populateJournal(DateTime selectedDate, {bool forceReload = false}) async {
    state = await _journalLog.getMedicationsForTheDay(selectedDate, forceReload: forceReload);
  }

  Future<void> pillTaken(IntakeLog log, DateTime date) async {
    log.isTaken = true;
    
    // Get the normalized date
    final normalizedDate = date.normalize();
    
    // Save the updated logs to persistent storage
    await _journalLog.saveMedicationLogs(normalizedDate);
  }
  
  /// Force reload all medication data from storage
  Future<void> forceReloadMedicationData(DateTime selectedDate) async {
    // Clear all cached data
    _journalLog.clearAllCachedMedicationLogs();
    
    // Reload from storage for the specific date with force reload flag
    await populateJournal(selectedDate, forceReload: true);
    
    "Medication data forcefully reloaded for ${selectedDate.toString()}".log();
  }

  /// Getter to access the journal log
  JournalLog get journalLog => _journalLog;

  /// Get the days of the week with the most missed doses
  /// Uses in-memory data only - ensure data is loaded before calling
  List<String> getMissedDoseDays() {
    final Map<String, int> missedDoseDays = {};
    
    // Use the existing medicationLogs data
    _journalLog.medicationLogs.forEach((date, intakeLogs) {
      if (intakeLogs.isNotEmpty) {
        final String dayOfWeek = DateFormat('EEEE').format(date);
        final int missedDoses = intakeLogs.where((log) => !log.isTaken).length;
        if (missedDoses > 0) {
          missedDoseDays.update(dayOfWeek, (count) => count + missedDoses, 
              ifAbsent: () => missedDoses);
        }
      }
    });

    // Get the top 2 days with most missed doses
    if (missedDoseDays.isEmpty) {
      return [];
    }
    
    final sortedDays = missedDoseDays.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return sortedDays.take(2).map((e) => e.key).toList();
  }
}

final pillIntakeProvider = StateNotifierProvider<PillIntakeNotifier, List<IntakeLog>>((ref) => PillIntakeNotifier());
