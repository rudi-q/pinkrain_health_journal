import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinkrain/features/journal/presentation/journal_screen.dart';
import 'package:pinkrain/features/journal/presentation/medication_notification_widget.dart';

/// A wrapper for the JournalScreen that adds medication notification functionality
/// This demonstrates how to use the MedicationNotificationWidget without modifying
/// the existing JournalScreen code
class JournalScreenWrapper extends ConsumerWidget {
  const JournalScreenWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wrap the JournalScreen with the MedicationNotificationWidget
    // This adds the medication notification functionality without
    // modifying the JournalScreen code
    return MedicationNotificationWidget(
      child: const JournalScreen(),
    );
  }
}
