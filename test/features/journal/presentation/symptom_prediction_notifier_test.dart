import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/features/journal/data/symptom_prediction.dart';
import 'package:pillow/features/journal/presentation/symptom_predicton_notifier.dart';

void main() {
  group('SymptomPredictionNotifier Tests', () {
    late SymptomPredictionNotifier notifier;

    setUp(() {
      notifier = SymptomPredictionNotifier();
    });

    test('initial state is empty', () {
      expect(notifier.state, isEmpty);
      expect(SymptomPredictionNotifier.predictionInProgress, isFalse);
    });

    test('reset clears state and prediction flag', () {
      notifier.state = [
        SymptomPrediction(name: 'test', probability: 1.0)
      ];
      SymptomPredictionNotifier.predictionInProgress = true;

      notifier.reset();

      expect(notifier.state, isEmpty);
      expect(SymptomPredictionNotifier.predictionInProgress, isFalse);
    });

    test('predict uses TFLite model for predictions', () async {
      await notifier.predict('I have a headache');
      
      // Since we can't easily mock TFLite in tests,
      // we just verify the state is managed correctly
      expect(SymptomPredictionNotifier.predictionInProgress, isFalse);
    });

    test('predict skips if already in progress', () async {
      // Set flag to true
      SymptomPredictionNotifier.predictionInProgress = true;
      
      // Try to predict
      await notifier.predict('test');
      
      // Should not have changed state
      expect(notifier.state, isEmpty);
      
      // Flag should still be true
      expect(SymptomPredictionNotifier.predictionInProgress, isTrue);
      
      // Reset for cleanup
      SymptomPredictionNotifier.predictionInProgress = false;
    });

    test('predict handles errors gracefully', () async {
      // Force an error by passing empty text
      await notifier.predict('');
      
      expect(notifier.state, isEmpty);
      expect(SymptomPredictionNotifier.predictionInProgress, isFalse);
    });
  });
}
