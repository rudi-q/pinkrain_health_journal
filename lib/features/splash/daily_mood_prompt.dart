import 'package:flutter/material.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/features/wellness/presentation/components/mood_painter.dart';

class DailyMoodPrompt extends StatefulWidget {
  final Function onComplete;

  const DailyMoodPrompt({
    super.key, 
    required this.onComplete,
  });

  @override
  State<DailyMoodPrompt> createState() => _DailyMoodPromptState();
}

class _DailyMoodPromptState extends State<DailyMoodPrompt> {
  int selectedMood = 2; // Default to neutral mood
  final TextEditingController _feelingsController = TextEditingController();
  
  @override
  void dispose() {
    _feelingsController.dispose();
    super.dispose();
  }

  void _saveMoodAndContinue() async {
    await HiveService.saveUserMood(selectedMood, _feelingsController.text);
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
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
          const SizedBox(height: 15),
          
          // Subtitle
          Text(
            'We\'d love to know your mood today!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          
          // Mood selection
          Container(
            height: 110, 
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
                          width: 60, 
                          height: 60, 
                          decoration: BoxDecoration(
                            color: selectedMood == index ? Colors.pink[100] : Colors.grey[100],
                            shape: BoxShape.circle,
                            boxShadow: selectedMood == index ? [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              )
                            ] : null,
                          ),
                          child: CustomPaint(
                            painter: MoodPainter(index, selectedMood == index),
                            size: const Size(50, 50), 
                          ),
                        ),
                        const SizedBox(height: 10), 
                        Text(
                          _getMoodLabel(index),
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: selectedMood == index ? FontWeight.bold : FontWeight.normal,
                            color: selectedMood == index ? Colors.pink[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 25),
          
          // Text field for feelings
          TextField(
            controller: _feelingsController,
            maxLines: 3,
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
          ),
          const SizedBox(height: 25),
          
          // Submit button
          ElevatedButton(
            onPressed: _saveMoodAndContinue,
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
    );
  }
  
  String _getMoodLabel(int mood) {
    switch (mood) {
      case 0:
        return 'Very Sad';
      case 1:
        return 'Sad';
      case 2:
        return 'Neutral';
      case 3:
        return 'Happy';
      case 4:
        return 'Very Happy';
      default:
        return '';
    }
  }
}
