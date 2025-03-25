import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import 'core/util/helpers.dart';

class SymptomPredictor {
  late Map<String, int> wordIndex;
  late List<String> mlbClasses;
  late tfl.Interpreter interpreter;

  Future<void> loadModel() async {

    const String symptomModelsDir ="assets/models/symptom_prediction";

    // Verify model exists
    var modelExists = await rootBundle.loadString('$symptomModelsDir/model.tflite').then((value) => true).catchError((_) => false);
    if (!modelExists) {
      //throw Exception('Model does not exist at $symptomModelsDir/model.tflite');
    }

    // Load TFLite model
    interpreter = await tfl.Interpreter.fromAsset('$symptomModelsDir/model.tflite');

    // Load tokenizer word index
    String jsonString = await rootBundle.loadString('$symptomModelsDir/tokenizer.pkl');
    wordIndex = Map<String, int>.from(json.decode(jsonString));

    // Load mlb classes
    jsonString = await rootBundle.loadString('$symptomModelsDir/mlb.pkl');
    mlbClasses = List<String>.from(json.decode(jsonString));
  }

  List<int> tokenize(String text) {
    return text.toLowerCase().split(' ')
        .map((word) => wordIndex[word] ?? 0)
        .toList();
  }

  List<double> padSequence(List<int> sequence, int maxLen) {
    if (sequence.length > maxLen) {
      return sequence.sublist(0, maxLen).map((e) => e.toDouble()).toList();
    } else {
      return (sequence + List.filled(maxLen - sequence.length, 0))
          .map((e) => e.toDouble()).toList();
    }
  }

  Future<List<String>> predictSymptoms(String inputText) async {
    var tokens = tokenize(inputText.replaceAll("can't sleep", "not_sleep"));
    var paddedTokens = padSequence(tokens, 20);
  
    var input = [paddedTokens];
    var output = List.generate(1, (_) => List<double>.filled(326, 0));
  
    interpreter.run(input, output);
  
    var sortedIndices = output[0].asMap().entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  
    return sortedIndices.take(3)
        .map((e) => e.key)
        .map((i) => mlbClasses[i])
        .toList();
  }
}

void main() async {
  //WidgetsFlutterBinding.ensureInitialized();

  final predictor = SymptomPredictor();
  await predictor.loadModel();

  final symptoms = await predictor.predictSymptoms("I can't sleep at night");
  print(symptoms.isEmpty);
}
