/// Main chart factory for creating DRY, reusable wellness charts
import 'package:flutter/material.dart';
import 'package:cristalyse/cristalyse.dart';
import 'chart_data_models.dart';
import 'chart_themes.dart';
import 'chart_interactions.dart';

/// Factory for creating consistent wellness charts with minimal code duplication
class WellnessChartFactory {
  /// Create a mood trend line chart
  static Widget buildMoodTrendChart({
    required List<MoodDataPoint> moodData,
    required ChartTimeRange timeRange,
    required DateTime selectedDate,
    WellnessChartConfig? config,
    Function(dynamic)? onDataPointTap,
  }) {
    // Convert mood data to chart format
    final chartData = moodData.asMap().entries.map((entry) {
      return entry.value.toChartData(entry.key);
    }).toList();

    // Create the chart configuration
    final chartConfig = config ?? WellnessChartConfig(
      title: 'Mood Trends',
      description: _getMoodTrendDescription(timeRange, selectedDate),
    );

    if (chartData.isEmpty) {
      return _buildEmptyState('No mood data available for this period');
    }

    return _buildChartContainer(
      config: chartConfig,
      child: SizedBox(
        height: chartConfig.height,
        child: CristalyseChart()
            .data(chartData)
            .mapping(x: 'x', y: 'y')
            .geomArea(
              alpha: 0.2,
              strokeWidth: 0,
            )
            .geomLine(
              strokeWidth: 3.0,
            )
            .geomPoint(
              size: 8.0,
            )
            .scaleXContinuous()
            .scaleYContinuous(
              min: (MoodScale.minMood - 0.5).toDouble(),
              max: (MoodScale.maxMood + 0.5).toDouble(),
              labels: (value) => MoodScale.getMoodEmoji(value.toDouble()),
            )
            .theme(WellnessChartThemes.moodTrend)
            .animate(duration: const Duration(milliseconds: 800))
            .build(),
      ),
    );
  }

  /// Create a correlation analysis bar chart
  static Widget buildCorrelationChart({
    required List<CorrelationDataPoint> correlationData,
    WellnessChartConfig? config,
    Function(dynamic)? onDataPointTap,
  }) {
    // Convert correlation data to chart format
    final chartData = correlationData.asMap().entries.map((entry) {
      return entry.value.toChartData(entry.key);
    }).toList();

    // Create the chart configuration
    final chartConfig = config ?? const WellnessChartConfig(
      title: 'Correlation Analysis',
      description: 'Discover relationships between your wellness factors',
    );

    if (chartData.isEmpty) {
      return _buildEmptyState('No correlation data available');
    }

    return _buildChartContainer(
      config: chartConfig,
      child: SizedBox(
        height: chartConfig.height,
        child: CristalyseChart()
            .data(chartData)
            .mapping(x: 'x', y: 'y', color: 'y')
            .geomBar(
              width: 0.7,
              borderRadius: BorderRadius.circular(6.0),
            )
            .scaleXOrdinal(
              labels: (value) => _getCorrelationFactorLabel(value.toInt(), correlationData),
            )
            .scaleYContinuous(
              min: -1.0,
              max: 1.0,
              labels: (value) => InteractionHelpers.formatCorrelationLabel(value.toDouble()),
            )
            .theme(WellnessChartThemes.correlation)
            .animate(duration: const Duration(milliseconds: 600))
            .build(),
      ),
    );
  }

  /// Create a wellness prediction chart with confidence intervals
  static Widget buildPredictionChart({
    required List<PredictionDataPoint> predictionData,
    WellnessChartConfig? config,
    Function(dynamic)? onDataPointTap,
  }) {
    // Separate historical and prediction data
    final historicalData = predictionData
        .where((point) => point.isHistorical)
        .toList()
        .asMap()
        .entries
        .map((entry) => entry.value.toChartData(entry.key))
        .toList();

    final futureData = predictionData
        .where((point) => !point.isHistorical)
        .toList()
        .asMap()
        .entries
        .map((entry) {
      final adjustedIndex = entry.key + historicalData.length;
      return entry.value.toChartData(adjustedIndex);
    }).toList();

    // Create the chart configuration
    final chartConfig = config ?? const WellnessChartConfig(
      title: 'Mood Forecast',
      description: 'Forecasting your mood for the next 7 days based on historical patterns',
      secondaryColor: Color(0xFF9B59B6),
    );

    if (predictionData.isEmpty) {
      return _buildEmptyState('No prediction data available');
    }

    // For now, create a simplified prediction chart with just the basic line
    final allData = [...historicalData, ...futureData];
    
    return _buildChartContainer(
      config: chartConfig,
      child: Column(
        children: [
          SizedBox(
            height: chartConfig.height,
            child: CristalyseChart()
                .data(allData)
                .mapping(x: 'x', y: 'y', color: 'isHistorical')
                .geomLine(
                  strokeWidth: 3.0,
                )
                .geomPoint(
                  size: 8.0,
                )
                .scaleXContinuous()
                .scaleYContinuous(
                  min: (MoodScale.minMood - 0.5).toDouble(),
                  max: (MoodScale.maxMood + 0.5).toDouble(),
                  labels: (value) => MoodScale.getMoodEmoji(value.toDouble()),
                )
                .theme(WellnessChartThemes.prediction)
                .animate(duration: const Duration(milliseconds: 1000))
                .build(),
          ),
          const SizedBox(height: ChartStyling.standardSpacing),
          _buildPredictionLegend(),
        ],
      ),
    );
  }

  // Private helper methods

  /// Build a standard chart container with consistent styling
  static Widget _buildChartContainer({
    required WellnessChartConfig config,
    required Widget child,
  }) {
    return Container(
      padding: ChartStyling.chartPadding,
      decoration: ChartStyling.chartContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart header
          Row(
            children: [
              Text(
                config.title,
                style: ChartStyling.chartTitle,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                color: config.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Analytics',
                  style: ChartStyling.smallLabel.copyWith(
                    color: config.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            config.description,
            style: ChartStyling.chartDescription,
          ),
          const SizedBox(height: ChartStyling.standardSpacing),
          child,
        ],
      ),
    );
  }

  /// Build empty state widget for charts with no data
  static Widget _buildEmptyState(String message) {
    return Container(
      padding: ChartStyling.chartPadding,
      decoration: ChartStyling.chartContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_neutral,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Get mood trend description based on time range and date
  static String _getMoodTrendDescription(ChartTimeRange timeRange, DateTime selectedDate) {
    switch (timeRange) {
      case ChartTimeRange.day:
        return 'Your mood for ${_formatDate(selectedDate)}';
      case ChartTimeRange.month:
        return 'Your daily mood trends for ${_formatMonth(selectedDate)}';
      case ChartTimeRange.year:
        return 'Your monthly mood trends for ${selectedDate.year}';
    }
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Format month for display
  static String _formatMonth(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Get short correlation factor label for display
  static String _getCorrelationFactorLabel(int index, List<CorrelationDataPoint> data) {
    if (index >= 0 && index < data.length) {
      final factor = data[index].factor;
      // Abbreviate long factor names
      if (factor == 'Medication Adherence') return 'Med';
      if (factor == 'Sleep Quality') return 'Sleep';
      if (factor == 'Exercise') return 'Exercise';
      if (factor == 'Screen Time') return 'Screen';
      if (factor == 'Social Interaction') return 'Social';
      return factor.length > 8 ? '${factor.substring(0, 8)}...' : factor;
    }
    return '';
  }

  /// Build legend for prediction charts
  static Widget _buildPredictionLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 3,
              color: WellnessChartThemes.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              'Historical mood data',
              style: ChartStyling.legendText,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 12,
              height: 3,
              child: CustomPaint(
                painter: _DashedLinePainter(color: WellnessChartThemes.secondaryPurple),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Predicted mood trend',
              style: ChartStyling.legendText,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: WellnessChartThemes.secondaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Prediction confidence interval (80%)',
              style: ChartStyling.legendText,
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom painter for dashed lines in legends
class _DashedLinePainter extends CustomPainter {
  final Color color;
  
  _DashedLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    const dashWidth = 5;
    const dashSpace = 2;
    double startX = 0;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}