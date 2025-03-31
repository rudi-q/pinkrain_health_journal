import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/journal/presentation/symtom_predicton_notifier.dart';
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
  late List<SymptomPrediction> predictedSymptoms;
  bool _loadingSymptomsPrediction = false;

  @override
  void dispose() {
    _feelingsController.dispose();
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
        // Trigger symptom prediction when text changes
        final symptomPredictionNotifier = ref.read(symptomPredictionProvider.notifier);
        symptomPredictionNotifier.reset();
        if (value.length > 7) {
          // Only predict after some meaningful text
          symptomPredictionNotifier.predict(value);
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Possible Symptoms You Might\n Be Experiencing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 14),
              if (_loadingSymptomsPrediction)
                const CupertinoActivityIndicator(
                  radius: 10,
                ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: predictedSymptoms.map((symptom) {
              // Determine size category based on probability
              final double probability = symptom.probability;

              // Size categories
              double fontSize;
              double chipHeight;

              if (probability >= 0.4) {
                // High probability (70%+)
                fontSize = 14.0;
                chipHeight = 32.0;
              } else if (probability >= 0.1) {
                // Medium probability (40-69%)
                fontSize = 12.0;
                chipHeight = 28.0;
              } else {
                // Low probability (<40%)
                fontSize = 10.0;
                chipHeight = 24.0;
              }

              return Chip(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                labelPadding: EdgeInsets.symmetric(
                  horizontal: probability >= 0.7 ? 8.0 : 6.0,
                  vertical: 0,
                ),
                label: Text(
                  symptom.toString(),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: fontSize,
                    fontWeight: probability >= 0.7
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                avatar: Icon(
                  Icons.medical_services_outlined,
                  size: fontSize + 2,
                  color: Colors.blue[400],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}