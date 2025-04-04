import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/util/helpers.dart';  // Import helpers for logging
import '../data/symptom_prediction.dart';
import '../domain/tf_lite_symptom_pred.dart'; // Import the TFLite predictor

final symptomPredictionProvider =
    StateNotifierProvider<SymptomPredictionNotifier, List<SymptomPrediction>>(
  (ref) => SymptomPredictionNotifier(),
);

class SymptomPredictionNotifier extends StateNotifier<List<SymptomPrediction>> {
  static bool predictionInProgress = false;
  static const int maxPredictions = 6;  // Store top 6 predictions

  SymptomPredictionNotifier() : super([]);

  void reset() {
    state = [];
    predictionInProgress = false;  // Reset flag when clearing state
    "Symptom prediction state reset".log();
  }

  Future<void> predict(String text,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      if (predictionInProgress) {
        "Skipping prediction - already in progress".log();
        return;
      }

      reset();  // This also sets predictionInProgress = false
      predictionInProgress = true;
      "Starting TFLite symptom prediction for text: $text".log();

      // Use the TFLite model for prediction
      final predictions = await symptomPrediction(text);
      
      if (predictions.isNotEmpty) {
        // Take up to maxPredictions predictions
        state = predictions.take(maxPredictions).toList();
        "Generated ${state.length} TFLite symptom predictions".log();
      } else {
        "No predictions from TFLite model".log();
        state = [];
      }
    } catch (e, stack) {
      "Error during symptom prediction: $e\n$stack".log();
      state = [];  // Clear state on error
    } finally {
      predictionInProgress = false;  // Always reset flag
      "Symptom prediction completed".log();
    }
  }

  // Get initial predictions (top 3)
  List<SymptomPrediction> getInitialPredictions() {
    return state.take(3).toList();
  }

  // Get additional predictions (4th to 6th)
  List<SymptomPrediction> getAdditionalPredictions() {
    if (state.length <= 3) return [];
    return state.skip(3).take(3).toList();
  }
}
