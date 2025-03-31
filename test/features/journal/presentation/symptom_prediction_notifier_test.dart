import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/features/journal/data/symptom_prediction.dart';
import 'package:pillow/features/journal/presentation/symtom_predicton_notifier.dart';

void main() {
  late SymptomPredictionNotifier notifier;

  setUp(() {
    notifier = SymptomPredictionNotifier();
  });

  test('initial state is empty', () {
    expect(notifier.state, isEmpty);
  });

  test('reset clears the state', () {
    notifier.state = [
      SymptomPrediction(name: 'test', probability: 1.0)
    ];
    notifier.reset();
    expect(notifier.state, isEmpty);
  });

  test('predict falls back to keyword matching when no history', () async {
    await notifier.predict('I have a headache');
    expect(notifier.state.length, 1);
    expect(notifier.state.first.name, 'Headache');
    expect(notifier.state.first.probability, 0.9);
  });
}
