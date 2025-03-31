// Rename this file to symptom_prediction_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/hive_service.dart';
import '../data/symptom_prediction.dart';

final symptomPredictionProvider =
    StateNotifierProvider<SymptomPredictionNotifier, List<SymptomPrediction>>(
  (ref) => SymptomPredictionNotifier(),
);

class SymptomPredictionNotifier extends StateNotifier<List<SymptomPrediction>> {
  static const _historyDays = 30; // Analyze last 30 days by default

  SymptomPredictionNotifier() : super([]);

  void reset() {
    state = [];
  }

  Future<void> predict(String text, {DateTime? startDate, DateTime? endDate}) async {
    reset();
    
    // Define the date range for analysis
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(Duration(days: _historyDays));
    
    // Get all symptoms from the box within the date range
    final entries = await HiveService.getSymptomEntries(start, end);
    
    if (entries.isEmpty) {
      _handleEmptyHistory(text);
      return;
    }

    // Count symptom occurrences
    Map<String, int> symptomCounts = {};
    int totalEntries = 0;

    for (var entry in entries) {
      for (var symptom in entry.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
      totalEntries++;
    }

    // Convert counts to probabilities and create predictions
    state = symptomCounts.entries
        .map((e) => SymptomPrediction(
              name: e.key,
              probability: e.value / totalEntries,
            ))
        .toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));
  }

  void _handleEmptyHistory(String text) {
    if (text.isEmpty) return;
    
    if (text.toLowerCase().contains('headache')) {
      state = [SymptomPrediction(name: 'Headache', probability: 0.9)];
    } else if (text.toLowerCase().contains('tired')) {
      state = [SymptomPrediction(name: 'Fatigue', probability: 0.85)];
    }
  }
}
