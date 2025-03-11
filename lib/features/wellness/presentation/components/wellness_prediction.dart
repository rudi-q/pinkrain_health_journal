import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WellnessPrediction extends StatelessWidget {
  const WellnessPrediction({super.key});

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
              const Text(
                'Mood Forecast',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Predictive Analytics',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Forecasting your mood for the next 7 days based on historical patterns',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              _createPredictionChartData(),
            ),
          ),
          const SizedBox(height: 16),
          _buildPredictionLegend(),
        ],
      ),
    );
  }

  LineChartData _createPredictionChartData() {
    // Generate historical data (past 7 days)
    final historicalSpots = List.generate(7, (index) {
      // Create a pattern with some randomness
      double baseValue = 2.0 + (index % 7) * 0.2;
      if (baseValue > 3.0) baseValue = 4.0 - baseValue;
      
      // Add some randomness
      double moodValue = baseValue + (DateTime.now().millisecond % 10) / 10 - 0.5;
      
      // Clamp to valid range
      moodValue = moodValue.clamp(0.0, 4.0);
      
      return FlSpot(index.toDouble(), moodValue);
    });
    
    // Generate prediction data (next 7 days)
    final predictionSpots = List.generate(7, (index) {
      // Base the prediction on the pattern from historical data
      // In a real app, this would use a proper prediction algorithm
      int pastIndex = (index + 3) % 7; // Offset to create a pattern
      double baseValue = historicalSpots[pastIndex].y;
      
      // Add a slight upward trend (assuming interventions are working)
      baseValue += index * 0.05;
      
      // Add confidence interval variation (less certain further in future)
      double uncertainty = index * 0.03;
      baseValue += uncertainty * (index % 2 == 0 ? 1 : -1);
      
      // Clamp to valid range
      baseValue = baseValue.clamp(0.0, 4.0);
      
      return FlSpot((index + 7).toDouble(), baseValue);
    });

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: _leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: 13,
      minY: 0,
      maxY: 4,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.grey[800]!.withAlpha(204), // 0.8 opacity = 204 alpha
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final isHistorical = touchedSpot.x < 7;
              final day = isHistorical 
                  ? 'Past day ${touchedSpot.x.toInt() + 1}'
                  : 'Future day ${touchedSpot.x.toInt() - 6}';
              
              String mood;
              final moodValue = touchedSpot.y;
              if (moodValue < 1) {
                mood = 'Very Sad';
              } else if (moodValue < 2) {
                mood = 'Sad';
              } else if (moodValue < 3) {
                mood = 'Neutral';
              } else if (moodValue < 4) {
                mood = 'Happy';
              } else {
                mood = 'Very Happy';
              }
              
              return LineTooltipItem(
                '$day\n$mood',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        // Historical data line
        LineChartBarData(
          spots: historicalSpots,
          isCurved: true,
          color: Colors.blue[400],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: Colors.blue[400]!,
              );
            },
          ),
        ),
        // Prediction data line
        LineChartBarData(
          spots: predictionSpots,
          isCurved: true,
          color: Colors.purple[300],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: Colors.purple[300]!,
              );
            },
          ),
          // Add a dash pattern to indicate prediction
          dashArray: [5, 2],
        ),
        // Upper confidence interval
        LineChartBarData(
          spots: predictionSpots.map((spot) {
            // Increase confidence interval the further in the future
            final dayInFuture = spot.x - 7;
            final confidenceInterval = 0.2 + (dayInFuture * 0.05);
            return FlSpot(spot.x, (spot.y + confidenceInterval).clamp(0, 4));
          }).toList(),
          isCurved: true,
          color: Colors.purple[200]!.withAlpha(128), // 0.5 opacity = 128 alpha
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          dashArray: [3, 2],
        ),
        // Lower confidence interval
        LineChartBarData(
          spots: predictionSpots.map((spot) {
            // Increase confidence interval the further in the future
            final dayInFuture = spot.x - 7;
            final confidenceInterval = 0.2 + (dayInFuture * 0.05);
            return FlSpot(spot.x, (spot.y - confidenceInterval).clamp(0, 4));
          }).toList(),
          isCurved: true,
          color: Colors.purple[200]!.withAlpha(128), // 0.5 opacity = 128 alpha
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          dashArray: [3, 2],
        ),
      ],
      // Add a vertical line to separate historical from prediction
      extraLinesData: ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: 6.5,
            color: Colors.grey.withAlpha(26), // 0.1 opacity = 26 alpha
            strokeWidth: 1,
            dashArray: [5, 5],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(bottom: 8),
              style: TextStyle(
                color: Colors.grey[600]!,
                fontSize: 10,
              ),
              labelResolver: (line) => 'Today',
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final int index = value.toInt();
    String text = '';
    
    // Show only every other day for clarity
    if (index % 2 == 0) {
      if (index < 7) {
        // Past days
        final daysAgo = 6 - index;
        text = daysAgo == 0 ? 'Today' : '$daysAgo d ago';
      } else {
        // Future days
        final daysAhead = index - 6;
        text = '+$daysAhead d';
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    String text = '';
    
    if (value % 1 == 0) {
      switch (value.toInt()) {
        case 0:
          text = '😢';
          break;
        case 1:
          text = '😔';
          break;
        case 2:
          text = '😐';
          break;
        case 3:
          text = '😊';
          break;
        case 4:
          text = '😁';
          break;
      }
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPredictionLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 3,
              color: Colors.blue[400],
            ),
            const SizedBox(width: 8),
            Text(
              'Historical mood data',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
                painter: _DashedLinePainter(color: Colors.purple[300]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Predicted mood trend',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CustomPaint(
                painter: _ConfidenceIntervalPainter(color: Colors.purple[200]!.withAlpha(128)), // 0.5 opacity = 128 alpha
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Prediction confidence interval (80%)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Forecast: Your mood is predicted to improve over the next week, with highest mood likely on day 5',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

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

class _ConfidenceIntervalPainter extends CustomPainter {
  final Color color;
  
  _ConfidenceIntervalPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(0, 2)
      ..lineTo(size.width, 2)
      ..lineTo(size.width, size.height - 2)
      ..lineTo(0, size.height - 2)
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Draw dashed borders
    final borderPaint = Paint()
      ..color = color.withAlpha(204) // 0.8 opacity = 204 alpha
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Top dashed line
    double startX = 0;
    const dashWidth = 3;
    const dashSpace = 2;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 2),
        Offset(startX + dashWidth, 2),
        borderPaint,
      );
      startX += dashWidth + dashSpace;
    }
    
    // Bottom dashed line
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height - 2),
        Offset(startX + dashWidth, size.height - 2),
        borderPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
