import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/data/journal_log.dart';
import 'package:pinkrain/features/journal/presentation/journal_notifier.dart';
import 'package:pinkrain/features/treatment/services/medication_notification_service.dart';

/// State class for the JournalMedicationNotifier
class JournalMedicationState {
  final List<IntakeLog> untakenMedications;
  final bool isLoading;

  const JournalMedicationState({
    this.untakenMedications = const [],
    this.isLoading = false,
  });

  JournalMedicationState copyWith({
    List<IntakeLog>? untakenMedications,
    bool? isLoading,
  }) {
    return JournalMedicationState(
      untakenMedications: untakenMedications ?? this.untakenMedications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Riverpod provider for JournalMedicationNotifier
final journalMedicationNotifierProvider = StateNotifierProvider<JournalMedicationNotifier, JournalMedicationState>((ref) {
  return JournalMedicationNotifier(ref);
});

/// Helper class to handle medication notifications in the Journal screen
/// This class is designed to be used with the JournalScreen without modifying
/// its existing code.
class JournalMedicationNotifier extends StateNotifier<JournalMedicationState> {
  final Ref _ref;
  final _medicationNotificationService = MedicationNotificationService();
  bool _isInitialized = false;

  JournalMedicationNotifier(this._ref) : super(const JournalMedicationState()) {
    initialize();
  }

  /// Initialize the medication notification service
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _medicationNotificationService.initialize();
      _isInitialized = true;
    }
  }

  /// Check for untaken medications and show notifications
  /// This should be called when the JournalScreen is opened
  Future<void> checkUntakenMedications() async {
    await initialize();

    // Set loading state
    state = state.copyWith(isLoading: true);

    try {
      // Get today's medications from the provider
      final pillIntakeNotifier = _ref.read(pillIntakeProvider.notifier);
      final today = DateTime.now();
      final medications = await pillIntakeNotifier.journalLog.getMedicationsForTheDay(today);

      // Filter for untaken medications
      final untakenMeds = medications.where((med) => !med.isTaken).toList();

      devPrint('🔍 Found ${untakenMeds.length} untaken medications');

      // Update state with untaken medications
      state = state.copyWith(
        untakenMedications: untakenMeds,
        isLoading: false,
      );

      // Directly show notifications for untaken medications
      if (untakenMeds.isNotEmpty) {
        devPrint('🔔 Showing notifications for ${untakenMeds.length} untaken medications');
        await _medicationNotificationService.showUntakenMedicationNotifications(untakenMeds);
      }
    } catch (e) {
      devPrint('❌ Error checking untaken medications: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Reset the medication check flag
  void resetMedicationCheck() {
    state = state.copyWith(untakenMedications: []);
  }
}

/// Extension method for ConsumerState<T> to easily add medication notification
/// functionality to any widget without modifying its existing code
extension MedicationNotifierExtension on ConsumerState {
  /// Check for untaken medications and show notifications
  Future<void> checkUntakenMedications() async {
    await ref.read(journalMedicationNotifierProvider.notifier).checkUntakenMedications();
  }

  /// Reset the medication check flag
  void resetMedicationCheck() {
    ref.read(journalMedicationNotifierProvider.notifier).resetMedicationCheck();
  }
}
