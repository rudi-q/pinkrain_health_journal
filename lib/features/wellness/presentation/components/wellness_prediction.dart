import 'package:flutter/material.dart';
import 'package:cristalyse/cristalyse.dart';
import 'charts/chart_data_models.dart';

class WellnessPrediction extends StatelessWidget {
  const WellnessPrediction({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate sample prediction data - in real app this would come from ML model
    final predictionData = _generateSamplePredictionData();
    
    // Convert to basic chart data format
    final chartData = predictionData.asMap().entries.map((entry) {
      return {
        'x': entry.key.toDouble(),
        'y': entry.value.predicted,
        'isHistorical': entry.value.isHistorical,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Predictive Analytics',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CristalyseChart()
                .data(chartData)
                .mapping(x: 'x', y: 'y', color: 'isHistorical')
                .geomLine(strokeWidth: 3.0)
                .geomPoint(size: 6.0)
                .scaleXContinuous()
                .scaleYContinuous(
                  min: 0.5,
                  max: 5.5,
                )
                .theme(ChartTheme.defaultTheme())
                .build(),
          ),
        ],
      ),
    );
  }

  /// Generate sample prediction data for demonstration
  List<PredictionDataPoint> _generateSamplePredictionData() {
    final now = DateTime.now();
    final dataPoints = <PredictionDataPoint>[];
    
    // Generate historical data (past 7 days)
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Create a pattern with some randomness
      double baseValue = 2.0 + (i % 7) * 0.2;
      if (baseValue > 3.0) baseValue = 4.0 - baseValue;
      
      // Add some randomness
      double moodValue = baseValue + (DateTime.now().millisecond % 10) / 10 - 0.5;
      
      // Clamp to valid range
      moodValue = moodValue.clamp(1.0, 5.0);
      
      dataPoints.add(PredictionDataPoint(
        date: date,
        predicted: moodValue,
        upperConfidence: moodValue,
        lowerConfidence: moodValue,
        isHistorical: true,
      ));
    }
    
    // Generate prediction data (next 7 days)
    for (int i = 1; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      
      // Base the prediction on pattern from historical data
      int pastIndex = (i + 3) % 7;
      double baseValue = dataPoints[pastIndex].predicted;
      
      // Add a slight upward trend (assuming interventions are working)
      baseValue += i * 0.05;
      
      // Add confidence interval variation (less certain further in future)
      double uncertainty = i * 0.03;
      baseValue += uncertainty * (i % 2 == 0 ? 1 : -1);
      
      // Clamp to valid range
      baseValue = baseValue.clamp(1.0, 5.0);
      
      // Calculate confidence intervals
      final confidenceRange = 0.2 + (i * 0.05);
      final upper = (baseValue + confidenceRange).clamp(1.0, 5.0);
      final lower = (baseValue - confidenceRange).clamp(1.0, 5.0);
      
      dataPoints.add(PredictionDataPoint(
        date: date,
        predicted: baseValue,
        upperConfidence: upper,
        lowerConfidence: lower,
        isHistorical: false,
      ));
    }
    
    return dataPoints;
  }
}
