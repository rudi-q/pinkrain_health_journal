import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CorrelationAnalysis extends StatelessWidget {
  const CorrelationAnalysis({super.key});

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
            child: BarChart(
              _createBarChartData(),
            ),
          ),
          const SizedBox(height: 16),
          _buildCorrelationLegend(),
        ],
      ),
    );
  }

  BarChartData _createBarChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 1.0,
      minY: -1.0,
      groupsSpace: 12,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.grey[100]!,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String factor;
            switch (groupIndex) {
              case 0:
                factor = 'Medication Adherence';
                break;
              case 1:
                factor = 'Sleep Quality';
                break;
              case 2:
                factor = 'Exercise';
                break;
              case 3:
                factor = 'Screen Time';
                break;
              case 4:
                factor = 'Social Interaction';
                break;
              default:
                factor = '';
            }
            return BarTooltipItem(
              '$factor\n${(rod.toY * 100).toStringAsFixed(0)}% correlation',
              const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
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
            getTitlesWidget: _bottomTitles,
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 0.5,
            getTitlesWidget: _leftTitles,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      gridData: FlGridData(
        show: true,
        checkToShowHorizontalLine: (value) => value % 0.5 == 0,
        getDrawingHorizontalLine: (value) {
          if (value == 0) {
            return FlLine(
              color: Colors.grey[400],
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          }
          return FlLine(
            color: Colors.grey[200],
            strokeWidth: 0.8,
          );
        },
      ),
      barGroups: _getBarGroups(),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    // Sample correlation data
    // Positive values indicate positive correlation with mood
    // Negative values indicate negative correlation with mood
    final data = [
      0.85,  // Medication Adherence
      0.72,  // Sleep Quality
      0.63,  // Exercise
      -0.58, // Screen Time
      0.45,  // Social Interaction
    ];
    
    return data.asMap().entries.map((entry) {
      final int index = entry.key;
      final double value = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: LinearGradient(
              colors: value >= 0 
                ? [Colors.green[100]!, Colors.green[300]!]
                : [Colors.red[100]!, Colors.red[300]!],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 22,
            borderRadius: value >= 0
                ? const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  )
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
          ),
        ],
      );
    }).toList();
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    final titles = ['Med', 'Sleep', 'Exercise', 'Screen', 'Social'];
    
    final Widget text = Text(
      titles[value.toInt()],
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    String text;
    
    if (value == 1) {
      text = '+100%';
    } else if (value == 0.5) {
      text = '+50%';
    } else if (value == 0) {
      text = '0%';
    } else if (value == -0.5) {
      text = '-50%';
    } else if (value == -1) {
      text = '-100%';
    } else {
      return Container();
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

  Widget _buildCorrelationLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[100]!, Colors.green[300]!],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Positive correlation: As this factor increases, your mood improves',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
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
                gradient: LinearGradient(
                  colors: [Colors.red[100]!, Colors.red[300]!],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Negative correlation: As this factor increases, your mood declines',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Based on analysis of your mood data and wellness tracking over the past month',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}
