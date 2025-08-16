import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/journal/domain/tf_lite_symptom_pred.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test TFLite symptom predictions on Android platform',
      (WidgetTester tester) async {
    // Set up a basic app to provide platform context
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(),
        ),
      ),
    );

    final predictor = SymptomPredictor();
    await predictor.loadModel();

    final inputs = [
      "Having frequent urination issues",
      "My legs are swollen and painful",
      "Experiencing severe menstrual cramps",
      "Having chills and fever symptoms",
      "My neck is stiff and painful",
      "Feeling very restless and agitated",
      "Having breathing difficulties and wheezing",
      "My jaw hurts when chewing"
    ];

    devPrint(
        '\n=== Testing Symptom Predictions for Natural Language Inputs ===\n');

    for (final input in inputs) {
      devPrint('\nInput: "$input"');
      final predictions = await predictor.predictSymptoms(input);
      devPrint('Predictions:');
      for (final pred in predictions) {
        devPrint(
            '  - ${pred.name}: ${(pred.probability * 100).toStringAsFixed(1)}%');
      }
      devPrint('---');
    }
  });
}
