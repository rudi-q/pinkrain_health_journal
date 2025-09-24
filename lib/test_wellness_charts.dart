import 'package:flutter/material.dart';
import 'features/wellness/presentation/components/mood_trend_chart.dart';
import 'features/wellness/presentation/components/correlation_analysis.dart';
import 'features/wellness/presentation/components/wellness_prediction.dart';

class TestWellnessCharts extends StatelessWidget {
  const TestWellnessCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Wellness Charts')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Testing Cristalyse Charts:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test Mood Trend Chart
            MoodTrendChart(
              timeRange: 'month',
              moodDataFetcher: (date) async {
                // Sample mood data for testing
                return {
                  'mood': 3.5 + (date.day % 5) * 0.3, // Varies between ~3.5-5
                  'note': 'Test note for ${date.day}/${date.month}',
                };
              },
            ),
            
            const SizedBox(height: 20),
            
            // Test Correlation Analysis Chart
            const CorrelationAnalysis(),
            
            const SizedBox(height: 20),
            
            // Test Wellness Prediction Chart
            const WellnessPrediction(),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

/// Add this to your main.dart or route to test the charts:
/// 
/// MaterialPageRoute(
///   builder: (context) => const TestWellnessCharts(),
/// )