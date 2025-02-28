import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillow/core/util/helpers.dart';

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

  PillIntakeNotifier() : super([]);

  void populateJournal(DateTime selectedDate) => state = _journalLog.getMedicationsForTheDay(selectedDate);

  void pillTaken(IntakeLog log) {
    log.isTaken = true;
  }
}

final pillIntakeProvider = StateNotifierProvider<PillIntakeNotifier, List<IntakeLog>>((ref) => PillIntakeNotifier());
