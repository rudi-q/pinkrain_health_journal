import 'package:flutter/material.dart';

class PersonalizedInsights extends StatelessWidget {
  final String timeRange; // 'day', 'month', or 'year'

  const PersonalizedInsights({
    super.key,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26), // 0.1 opacity = 26 alpha
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Personalized Insights',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'AI-Powered',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightCards(),
          const SizedBox(height: 12),
          Text(
            'Insights are generated based on your personal data patterns and scientific research',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCards() {
    // Generate insights based on time range
    final insights = _getInsightsForTimeRange();
    
    return Column(
      children: insights.map((insight) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InsightCard(
            title: insight['title'] as String,
            description: insight['description'] as String,
            icon: insight['icon'] as IconData,
            color: insight['color'] as Color,
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getInsightsForTimeRange() {
    switch (timeRange) {
      case 'day':
        return [
          {
            'title': 'Morning Routine Impact',
            'description': 'Your mood is typically 30% better on days when you take your medication before 9am.',
            'icon': Icons.access_time,
            'color': Colors.blue[100]!,
          },
          {
            'title': 'Screen Time Alert',
            'description': 'You tend to report lower mood scores after periods of extended screen time (>3 hours).',
            'icon': Icons.phone_android,
            'color': Colors.orange[100]!,
          },
        ];
      case 'month':
        return [
          {
            'title': 'Social Connection',
            'description': 'Your mood scores are consistently higher on days with social interactions. Consider scheduling more social activities.',
            'icon': Icons.people,
            'color': Colors.purple[100]!,
          },
          {
            'title': 'Sleep Pattern',
            'description': 'Your mood is most stable when you maintain a consistent sleep schedule. Your optimal bedtime appears to be around 10:30pm.',
            'icon': Icons.nightlight_round,
            'color': Colors.indigo[100]!,
          },
          {
            'title': 'Medication Effectiveness',
            'description': 'Your symptom reports show a 40% reduction in headaches when medication adherence is above 90%.',
            'icon': Icons.medication,
            'color': Colors.green[100]!,
          },
        ];
      case 'year':
        return [
          {
            'title': 'Seasonal Pattern',
            'description': 'Your mood tends to dip during winter months. Consider light therapy and vitamin D supplements from November to February.',
            'icon': Icons.wb_sunny,
            'color': Colors.amber[100]!,
          },
          {
            'title': 'Exercise Impact',
            'description': 'Months with regular exercise (3+ times per week) show 25% higher average mood scores.',
            'icon': Icons.fitness_center,
            'color': Colors.red[100]!,
          },
        ];
      default:
        return [
          {
            'title': 'Wellness Pattern',
            'description': 'Based on your data, we\'ve identified patterns that could help improve your wellbeing.',
            'icon': Icons.insights,
            'color': Colors.teal[100]!,
          },
        ];
    }
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(77), // 0.3 opacity = 77 alpha
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
