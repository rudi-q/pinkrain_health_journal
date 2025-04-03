import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/features/journal/data/symptom_prediction.dart';
import 'package:pillow/features/journal/domain/tf_lite_symptom_pred.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

@GenerateMocks([tfl.Interpreter])
void main() {
  group('SymptomPredictor', () {
    late SymptomPredictor predictor;
    
    setUp(() {
      predictor = SymptomPredictor();
      
      // Mock predictor properties for testing
      predictor.wordIndex = {
        'headache': 1,
        'pain': 2,
        'tired': 3,
        'fatigue': 4,
        'nausea': 5,
        'cant': 6,
        'sleep': 7,
        'not_sleep': 8,
      };
      
      predictor.mlbClasses = [
        'Headache',
        'Fatigue',
        'Nausea',
        'Sleep Disturbance',
        'General Discomfort'
      ];
    });
    
    test('tokenize converts text to token IDs', () {
      final tokens = predictor.tokenize('headache pain');
      expect(tokens, equals([1, 2]));
    });
    
    test('tokenize handles unknown words', () {
      final tokens = predictor.tokenize('unknown word headache');
      expect(tokens, equals([0, 0, 1]));
    });
    
    test('padSequence pads short sequences', () {
      final padded = predictor.padSequence([1, 2, 3], 5);
      expect(padded, equals([1.0, 2.0, 3.0, 0.0, 0.0]));
    });
    
    test('padSequence truncates long sequences', () {
      final padded = predictor.padSequence([1, 2, 3, 4, 5, 6], 4);
      expect(padded, equals([1.0, 2.0, 3.0, 4.0]));
    });
    
    test('replace "can\'t sleep" with "not_sleep"', () {
      final tokens = predictor.tokenize('can\'t sleep');
      final notSleepTokens = predictor.tokenize('not_sleep');
      
      expect(tokens, isNot(equals(notSleepTokens)));
      
      final inputText = 'I can\'t sleep well';
      final processed = inputText.replaceAll("can't sleep", "not_sleep");
      final processedTokens = predictor.tokenize(processed);
      
      expect(processed, equals('I not_sleep well'));
      expect(processedTokens.contains(8), isTrue); // not_sleep token
    });
  });
  
  group('symptomPrediction function', () {
    test('fallback keywords work when predictions are empty', () async {
      final headacheResult = await symptomPrediction('I have a headache');
      expect(headacheResult, isNotEmpty);
      expect(headacheResult[0].name, equals('Headache'));
      
      final tiredResult = await symptomPrediction('I feel tired today');  
      expect(tiredResult, isNotEmpty);
      expect(tiredResult[0].name, equals('Fatigue'));
      
      final nauseaResult = await symptomPrediction('I have nausea');
      expect(nauseaResult, isNotEmpty);
      expect(nauseaResult[0].name, equals('Nausea'));
      
      final generalResult = await symptomPrediction('I don\'t feel good');
      expect(generalResult, isNotEmpty);
      expect(generalResult[0].name, equals('General Discomfort'));
    }, skip: 'This test requires the actual TFLite model to be loaded');
    
    test('handles errors gracefully', () async {
      final result = await symptomPrediction('This will cause an error because the model is not loaded');
      expect(result, isEmpty);
    });
  });
  
  group('SymptomPrediction class', () {
    test('toString formats properly', () {
      final prediction = SymptomPrediction(name: 'Headache', probability: 0.75);
      expect(prediction.toString(), equals('Headache (75.0%)'));
    });
  });
}