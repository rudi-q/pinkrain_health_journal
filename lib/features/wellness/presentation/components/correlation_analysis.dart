import 'package:flutter/material.dart';
import 'package:cristalyse/cristalyse.dart';
import 'charts/chart_data_models.dart';

class CorrelationAnalysis extends StatelessWidget {
  const CorrelationAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample correlation data - in real app this would come from analysis
    final correlationData = [
      CorrelationDataPoint(
        factor: 'Medication Adherence',
        correlation: 0.85,
        description: 'Strong positive correlation with mood improvement',
      ),
      CorrelationDataPoint(
        factor: 'Sleep Quality',
        correlation: 0.72,
        description: 'Good sleep quality correlates with better mood',
      ),
      CorrelationDataPoint(
        factor: 'Exercise',
        correlation: 0.63,
        description: 'Regular exercise shows moderate positive impact',
      ),
      CorrelationDataPoint(
        factor: 'Screen Time',
        correlation: -0.58,
        description: 'Excessive screen time negatively impacts mood',
      ),
      CorrelationDataPoint(
        factor: 'Social Interaction',
        correlation: 0.45,
        description: 'Social activities have moderate positive effect',
      ),
    ];

    // Convert to basic chart data format
    final chartData = correlationData.asMap().entries.map((entry) {
      return {
        'x': entry.key.toDouble(),
        'y': entry.value.correlation,
        'factor': entry.value.factor,
        'description': entry.value.description,
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Correlation Analysis',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Discover relationships between your wellness factors',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CristalyseChart()
                .data(chartData)
                .mapping(x: 'x', y: 'y')
                .geomBar()
                .scaleXContinuous()
                .scaleYContinuous(
                  min: -1.0,
                  max: 1.0,
                )
                .theme(ChartTheme.defaultTheme())
                .build(),
          ),
        ],
      ),
    );
  }
}
