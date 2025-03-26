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

    try {
      // Load model as a byte buffer to verify it’s accessible
      final modelData = await rootBundle.load('$symptomModelsDir/model.tflite');
      print("Model size: ${modelData.lengthInBytes} bytes");

      // Create interpreter from buffer instead of asset directly
      interpreter = tfl.Interpreter.fromBuffer(modelData.buffer.asUint8List());
      print("Interpreter initialized successfully.");
    } catch (e) {
      throw Exception('Failed to load or initialize model: $e');
    }

    var inputTensor = interpreter.getInputTensor(0);
    var outputTensor = interpreter.getOutputTensor(0);
    devPrint("Input shape: ${inputTensor.shape}");
    devPrint("Output shape: ${outputTensor.shape}");

    // Load tokenizer as JSON
    String tokenizerString = await rootBundle.loadString('$symptomModelsDir/tokenizer.json');
    wordIndex = Map<String, int>.from(json.decode(tokenizerString));
    print("Tokenizer loaded with ${wordIndex.length} words.");

    // Load MLB classes as JSON
    String mlbString = await rootBundle.loadString('$symptomModelsDir/mlb.json');
    mlbClasses = List<String>.from(json.decode(mlbString));
    print("MLB classes loaded with ${mlbClasses.length} classes.");
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
