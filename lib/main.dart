import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillow/tf_lite_symtom_pred.dart';

import 'core/navigation/router.dart';
import 'core/services/hive_service.dart';
import 'core/util/helpers.dart';

/// Runs a sample prediction with the symptom predictor.
///
/// This function creates an instance of [SymptomPredictor], loads the model,
/// and then runs a prediction on the string "I can't sleep at night". The
/// result of the prediction is then printed to the console.
///
/// This is only intended as a sample and does not do anything in a real
/// application.
Future<void> symptomPrediction() async {
  try {
    final predictor = SymptomPredictor();
    print("Loading model...");
    await predictor.loadModel();
    print("Model loaded successfully.");
    final symptoms = await predictor.predictSymptoms("I can't sleep at night");
    print("Predicted symptoms: $symptoms");
  } catch (e, stackTrace) {
    print("Error in symptom prediction: $e");
    print("Stack trace: $stackTrace");
  }
}

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();

  await symptomPrediction();

  runApp(ProviderScope(child: const MyApp()));

}

class MyApp extends ConsumerWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: ThemeMode.light, // This will use the device's theme settings
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Outfit',
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Outfit',
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
    );
  }
}