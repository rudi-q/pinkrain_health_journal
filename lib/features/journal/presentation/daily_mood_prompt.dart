import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/journal/presentation/symptom_predicton_notifier.dart';
import 'package:pillow/features/wellness/presentation/components/mood_painter.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/symptom_prediction.dart';
import 'journal_screen.dart';

class DailyMoodPrompt extends ConsumerStatefulWidget {
  final Function onComplete;
  final DateTime?
      date; // Optional date parameter, defaults to today if not provided

  const DailyMoodPrompt({
    super.key,
    required this.onComplete,
    this.date,
  });

  @override
  ConsumerState<DailyMoodPrompt> createState() => DailyMoodPromptState();
}

class DailyMoodPromptState extends ConsumerState<DailyMoodPrompt> {
  int selectedMood = 2; // Default to neutral mood
  final TextEditingController _feelingsController = TextEditingController();
  late List<SymptomPrediction> predictedSymptoms =
      []; // Initialize with empty list
  final _isExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // Initialize predicted symptoms
    predictedSymptoms = ref.read(symptomPredictionProvider);
  }

  @override
  void dispose() {
    _feelingsController.dispose();
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  // Save the mood data to Hive
  void _saveMoodData() async {
    if (selectedMood != -1) {
      try {
        // Use the provided date or default to today
        final date = widget.date ?? DateTime.now();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        // Make sure the box is open before saving
        if (!Hive.isBoxOpen(HiveService.moodBoxName)) {
          await Hive.openBox(HiveService.moodBoxName);
        }

        final box = Hive.box(HiveService.moodBoxName);

        // Save the mood data
        await box.put('mood_$dateKey', {
          'mood': selectedMood,
          'description': _feelingsController.text,
          'timestamp': DateTime.now()
              .toIso8601String(), // Always use current timestamp for when it was recorded
        });

        // Save the user's current mood only if we're recording for today
        final today = DateTime.now();
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        if (isToday) {
          await HiveService.saveUserMood(
              selectedMood, _feelingsController.text);
        }

        // Call the onComplete callback
        widget.onComplete();
      } catch (e) {
        devPrint('Error saving mood data: $e');
        // Still call onComplete even if there's an error
        widget.onComplete();
      }
    } else {
      // Show error if no mood is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a mood'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to symptom predictions
    predictedSymptoms = ref.watch(symptomPredictionProvider);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Container contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Cute header
            Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.pink[400],
              ),
            ),
            const SizedBox(height: 10),

            // Mood selection
            _buildMoodSelection(),
            const SizedBox(height: 10),

            // Text field for feelings
            _buildFeelingsTextField(ref),
            const SizedBox(height: 10),

            // Symptom prediction container
            if (predictedSymptoms.isNotEmpty)
              Flexible(
                child: _buildSymptomPredictionContainer(),
              ),
            const SizedBox(height: 10),

            // Submit button
            ElevatedButton(
              onPressed: _saveMoodData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[100],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox _buildMoodSelection() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMood = index;
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selectedMood == index
                          ? Colors.pink[100]
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                      boxShadow: selectedMood == index
                          ? [
                              BoxShadow(
                                color: Colors.pink.withAlpha(76),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: //Text(getMoodEmoji(index))
                        CustomPaint(
                      painter: MoodPainter(index, selectedMood == index),
                      size: const Size(15, 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    getMoodLabel(index),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedMood == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedMood == index
                          ? Colors.pink[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  TextField _buildFeelingsTextField(WidgetRef ref) {
    return TextField(
      cursorColor: Colors.pink[400],
      controller: _feelingsController,
      maxLines: 3,
      onChanged: (value) {
        // Don't predict if text is too short
        if (value.length <= 7) {
          "Text too short for prediction (${value.length} chars)".log();
          return;
        }

        // Don't predict if already in progress
        if (SymptomPredictionNotifier.predictionInProgress) {
          "Prediction already in progress, skipping".log();
          return;
        }

        "Initiating prediction for possible symptoms".log();
        // Trigger symptom prediction when text changes
        try {
          final symptomPredictionNotifier =
              ref.read(symptomPredictionProvider.notifier);
          symptomPredictionNotifier.predict(value);
        } catch (e, stack) {
          "Error during symptom prediction: $e\n$stack".log();
        }
      },
      decoration: InputDecoration(
        hintText: 'Tell us more about how you\'re feeling...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(15),
      ),
    );
  }

  Container _buildSymptomPredictionContainer() {
    final notifier = ref.read(symptomPredictionProvider.notifier);
    final initialPredictions = notifier.getInitialPredictions();
    final additionalPredictions = notifier.getAdditionalPredictions();
    final hasMorePredictions = additionalPredictions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.pink[50]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink[100]!.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.pink[100]!.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: Colors.pink[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Possible Symptoms',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.pink[400],
                    fontSize: 16,
                  ),
                ),
              ),
              if (hasMorePredictions)
                ValueListenableBuilder<bool>(
                  valueListenable: _isExpandedNotifier,
                  builder: (context, isExpanded, child) {
                    return IconButton(
                      icon: Icon(
                        isExpanded ? Icons.remove : Icons.add,
                        color: Colors.pink[400],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _isExpandedNotifier.value = !isExpanded;
                      },
                    );
                  },
                ),
            ],
          ),
          if (initialPredictions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: _isExpandedNotifier,
              builder: (context, isExpanded, child) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...initialPredictions.map((symptom) => _buildSymptomChip(symptom)),
                    if (isExpanded) ...[
                      ...additionalPredictions.map((symptom) => _buildSymptomChip(symptom)),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomChip(SymptomPrediction symptom) {
    final double probability = symptom.probability;
    final bool isHighProbability = probability >= 0.4;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.pink[100]!.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink[100]!.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: isHighProbability ? 16 : 14,
            color: Colors.pink[300],
          ),
          const SizedBox(width: 6),
          Text(
            '${symptom.name} (${(probability * 100).toStringAsFixed(1)}%)',
            style: TextStyle(
              color: Colors.pink[700],
              fontSize: isHighProbability ? 14 : 12,
              fontWeight: isHighProbability ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
