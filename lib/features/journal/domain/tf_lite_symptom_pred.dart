import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../../../core/util/helpers.dart';
import '../data/symptom_prediction.dart';

class SymptomPredictor {
  late Map<String, int> wordIndex;
  late List<String> mlbClasses;
  late tfl.Interpreter interpreter;

  Future<void> loadModel() async {

    const String symptomModelsDir ="assets/models/symptom_prediction";

    try {
      // Load model as a byte buffer to verify it’s accessible
      final modelData = await rootBundle.load('$symptomModelsDir/model.tflite');
      devPrint("Model size: ${modelData.lengthInBytes} bytes");

      // Create interpreter from buffer instead of asset directly
      interpreter = tfl.Interpreter.fromBuffer(modelData.buffer.asUint8List());
      devPrint("Interpreter initialized successfully.");
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
    devPrint("Tokenizer loaded with ${wordIndex.length} words.");

    // Load MLB classes as JSON
    String mlbString = await rootBundle.loadString('$symptomModelsDir/mlb.json');
    mlbClasses = List<String>.from(json.decode(mlbString));
    devPrint("MLB classes loaded with ${mlbClasses.length} classes.");
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

  Future<List<SymptomPrediction>> predictSymptoms(String inputText) async {
    // Blacklisted symptoms that should never be predicted
    const blacklistedSymptoms = {'hypnic jerks'};
    
    var tokens = tokenize(inputText.replaceAll("can't sleep", "not_sleep"));
    var paddedTokens = padSequence(tokens, 20);
  
    var input = [paddedTokens];
    var output = List.generate(1, (_) => List<double>.filled(326, 0));
  
    interpreter.run(input, output);
  
    var sortedIndices = output[0].asMap().entries
        .where((entry) => !blacklistedSymptoms.contains(mlbClasses[entry.key]))  // Filter out blacklisted symptoms
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return sortedIndices.take(6)
        .map((e) => SymptomPrediction(
      name: mlbClasses[e.key],
      probability: e.value,
    )).toList();
  }
}

Future<List<SymptomPrediction>> symptomPrediction(String text) async {
  try {
    final predictor = SymptomPredictor();
    devPrint("Starting symptom prediction for text: ${text.substring(0, text.length > 20 ? 20 : text.length)}...");
    devPrint("Loading model...");
    await predictor.loadModel();
    devPrint("Model loaded successfully.");
    
    final predictions = await predictor.predictSymptoms(text);
    devPrint("Predicted symptoms count: ${predictions.length}");
    devPrint("Predicted symptoms: $predictions");

    if (predictions.isEmpty) {
      final lowerText = text.toLowerCase();
      if (lowerText.contains('headache')) {
        return [SymptomPrediction(name: 'Headache', probability: 1.0)];
      } else if (lowerText.contains('tired')) {
        return [SymptomPrediction(name: 'Fatigue', probability: 1.0)];
      } else if (lowerText.contains('nausea')) {
        return [SymptomPrediction(name: 'Nausea', probability: 1.0)];
      } else {
        return [SymptomPrediction(name: 'General Discomfort', probability: 1.0)];
      }
    }

    return predictions;
  } catch (e, stackTrace) {
    devPrint("Error in symptom prediction: $e");
    devPrint("Stack trace: $stackTrace");
    return [];
  }
}
