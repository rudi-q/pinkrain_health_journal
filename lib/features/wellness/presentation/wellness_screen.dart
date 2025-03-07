import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pillow/core/util/helpers.dart';

import '../../../core/widgets/bottom_navigation.dart';
import 'components/mood_painter.dart';
import 'components/scatter_plot_painter.dart';

class WellnessTrackerScreen extends StatefulWidget {
  const WellnessTrackerScreen({super.key});

  @override
  State<WellnessTrackerScreen> createState() => _WellnessTrackerScreenState();
}

class _WellnessTrackerScreenState extends State<WellnessTrackerScreen> {
  // Selected mood (0-4, where 3 is selected in the prototype)
  int selectedMood = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Date selector
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dateOption('day'),
                        _dateOption('month', isSelected: true),
                        _dateOption('year'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Wellness title and description
                Center(
                  child: Text(
                    "${DateTime.now().month.monthName}'s Wellness Report",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Track your journey and nurture your\nwhole self - mind and body together.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Mood tracker
                const Text(
                  'How are you feeling?',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    5,
                        (index) => _moodIcon(index),
                  ),
                ),

                const SizedBox(height: 20),

                // More details button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Want to share more details?',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),

                const SizedBox(height: 30),

                // Medication adherence
                const Text(
                  'Medication adherence',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 40,
                      lineWidth: 8,
                      percent: 0.85,
                      center: const Text(
                        '85%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      progressColor: Colors.purple[100],
                      backgroundColor: Colors.grey[200]!,
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "You've taken 85% of your\nmedications this month",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "That's better than last month\n(82%)",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Missed dose patterns
                const Text(
                  'Missed dose patterns',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _dayIndicator('Mon', true),
                        _dayIndicator('Tue', true),
                        _dayIndicator('Wed', false),
                        _dayIndicator('Thu', true),
                        _dayIndicator('Fri', true),
                        _dayIndicator('Sat', false),
                        _dayIndicator('Sun', true),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'You tend to miss evening doses on\nWednesdays and Saturdays',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Medication effectiveness
                const Text(
                  'Medication effectiveness',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Effectiveness scores are based on your\nreported symptom improvements',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 15),
                _effectivenessBar('Omeprazole', 9.0, Colors.green[200]!),
                const SizedBox(height: 8),
                _effectivenessBar('Omeprazole', 8.0, Colors.green[200]!),
                const SizedBox(height: 8),
                _effectivenessBar('Omeprazole', 4.3, Colors.purple[100]!),

                const SizedBox(height: 30),

                // Active symptoms and triggers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active symptoms',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _symptomItem(12, 'Headache', '12 occurrences this month', Colors.purple),
                          const SizedBox(height: 8),
                          _symptomItem(5, 'Fatigue', '5 occurrences this month', Colors.purple),
                          const SizedBox(height: 8),
                          _symptomItem(2, 'Dizziness', '2 occurrences this month', Colors.purple),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top triggers',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _triggerItem('Stress', Colors.pink[100]!),
                          const SizedBox(height: 8),
                          _triggerItem('Poor sleep', Colors.orange[100]!),
                          const SizedBox(height: 8),
                          _triggerItem('Screen time', Colors.yellow[200]!),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Medication impact
                const Text(
                  'Medication impact',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomPaint(
                        painter: ScatterPlotPainter(),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Strong positive correlation',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'When you take your medications\nregularly, your symptoms\ntypically improve within 2 days',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(context: context, currentRoute: 'wellness'),
    );
  }

  Widget _dateOption(String text, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _moodIcon(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = index;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: selectedMood == index ? Colors.grey[700] : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: CustomPaint(
            painter: MoodPainter(index, selectedMood == index),
            size: const Size(30, 20),
          ),
        ),
      ),
    );
  }

  Widget _dayIndicator(String day, bool isComplete) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? Colors.green[100] : Colors.pink[100],
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _effectivenessBar(String medication, double score, Color color) {
    // Assuming score is on a scale of 0-10
    final fillPercentage = score / 10.0;
    
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            medication,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              // Background bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Filled portion based on score
              FractionallySizedBox(
                widthFactor: fillPercentage,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _symptomItem(int count, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _triggerItem(String title, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}