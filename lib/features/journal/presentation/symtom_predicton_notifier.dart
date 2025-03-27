import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/symptom_prediction.dart';
import '../domain/tf_lite_symptom_pred.dart';


class SymptomPredictionNotifier extends StateNotifier<List<SymptomPrediction>> {
  SymptomPredictionNotifier() : super([]);

  void predict(String text) async {
    reset();
    state = await symptomPrediction(text);
  }
  void reset() => state = [];

}

final symptomPredictionProvider = StateNotifierProvider<SymptomPredictionNotifier, List<SymptomPrediction>>((ref) => SymptomPredictionNotifier());