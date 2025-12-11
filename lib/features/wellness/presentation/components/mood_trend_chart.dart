import 'package:flutter/material.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/util/helpers.dart' show devPrint;
import 'package:pinkrain/core/theme/colors.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'package:pinkrain/core/widgets/buttons.dart';
import 'package:cristalyse/cristalyse.dart';
import 'charts/chart_data_models.dart';
import 'charts/chart_factory.dart';

// Define a typedef for the mood data fetcher function
typedef MoodDataFetcher = Future<Map<String, dynamic>?> Function(DateTime date);

class MoodTrendChart extends StatefulWidget {
  final String timeRange;
  final DateTime selectedDate;
  final MoodDataFetcher? moodDataFetcher;

  MoodTrendChart({
    super.key,
    required this.timeRange,
    DateTime? selectedDate,
    this.moodDataFetcher,
  }) : selectedDate = selectedDate ?? DateTime.now();

  @override
  State<MoodTrendChart> createState() => _MoodTrendChartState();
}

class _MoodTrendChartState extends State<MoodTrendChart> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<MoodDataPoint> _moodData = [];

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  @override
  void didUpdateWidget(MoodTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if timeRange or selectedDate changes
    if (oldWidget.timeRange != widget.timeRange || 
        oldWidget.selectedDate != widget.selectedDate) {
      _loadMoodData();
    }
  }

  Future<void> _loadMoodData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final moodData = await _generateMoodData();
      
      if (moodData.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No mood data available for this period';
          _moodData = [];
        });
        return;
      }
      
      setState(() {
        _moodData = moodData;
        _isLoading = false;
      });
    } catch (e) {
      devPrint('Error loading mood data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load mood data: $e';
      });
    }
  }

  Future<List<MoodDataPoint>> _generateMoodData() async {
    List<MoodDataPoint> dataPoints = [];
    final referenceDate = widget.selectedDate;
    
    try {
      // Handle week case separately since it's not in the enum
      if (widget.timeRange == 'week') {
        // Generate daily data for a week (Monday to Sunday)
        final weekday = referenceDate.weekday; // 1 = Monday, 7 = Sunday
        final daysToSubtract = weekday - 1; // Days to subtract to get to Monday
        final startOfWeek = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: daysToSubtract));
        
        // Generate data for 7 days of the week
        for (int day = 0; day < 7; day++) {
          final date = startOfWeek.add(Duration(days: day));
          final moodData = await (widget.moodDataFetcher ?? HiveService.getMoodForDate)(date);
          
          if (moodData != null && moodData.containsKey('mood')) {
            dataPoints.add(MoodDataPoint(
              date: date,
              mood: moodData['mood'].toDouble(),
              note: moodData['note'] as String?,
            ));
          }
        }
        
        return dataPoints;
      }

      // Convert string timeRange to enum
      ChartTimeRange timeRange;
      switch (widget.timeRange) {
        case 'day':
          timeRange = ChartTimeRange.day;
          break;
        case 'month':
          timeRange = ChartTimeRange.month;
          break;
        case 'year':
          timeRange = ChartTimeRange.year;
          break;
        default:
          devPrint('Invalid time range: ${widget.timeRange}');
          return [];
      }

      switch (timeRange) {
        case ChartTimeRange.day:
          // Generate hourly data for a day
          final startOfDay = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
          
          // For day view, we'll check if there's a mood entry for this day
          final moodData = await (widget.moodDataFetcher ?? HiveService.getMoodForDate)(startOfDay);
          
          if (moodData != null && moodData.containsKey('mood')) {
            // If we have mood data for this day, create a single data point
            dataPoints.add(MoodDataPoint(
              date: startOfDay.add(const Duration(hours: 12)), // Position at noon
              mood: moodData['mood'].toDouble(),
              note: moodData['note'] as String?,
            ));
          }
          
          break;
          
        case ChartTimeRange.month:
          // Generate daily data for a month
          final startOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
          final daysInMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0).day;
          
          for (int day = 0; day < daysInMonth; day++) {
            final date = startOfMonth.add(Duration(days: day));
            final moodData = await (widget.moodDataFetcher ?? HiveService.getMoodForDate)(date);
            
            if (moodData != null && moodData.containsKey('mood')) {
              dataPoints.add(MoodDataPoint(
                date: date,
                mood: moodData['mood'].toDouble(),
                note: moodData['note'] as String?,
              ));
            }
          }
          
          break;
          
        case ChartTimeRange.year:
          // Generate monthly data for a year
          final startOfYear = DateTime(referenceDate.year, 1, 1);
          
          for (int month = 0; month < 12; month++) {
            final date = DateTime(startOfYear.year, month + 1, 1);
            
            // For each month, calculate the average mood
            double totalMood = 0;
            int moodCount = 0;
            
            final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
            for (int day = 1; day <= daysInMonth; day++) {
              final dayDate = DateTime(date.year, date.month, day);
              
              final moodData = await (widget.moodDataFetcher ?? HiveService.getMoodForDate)(dayDate);
              if (moodData != null && moodData.containsKey('mood')) {
                totalMood += moodData['mood'].toDouble();
                moodCount++;
              }
            }
            
            if (moodCount > 0) {
              dataPoints.add(MoodDataPoint(
                date: date,
                mood: totalMood / moodCount,
                note: null, // No specific note for aggregated data
              ));
            }
          }
          
          break;
      }
      
      return dataPoints;
    } catch (e) {
      devPrint('Error generating mood data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTokens.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTokens.borderLight,
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTokens.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTokens.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppTokens.iconPrimary, size: 44),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTokens.textPrimary,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Button.primary(
              onPressed: _loadMoodData,
              text: 'Retry',
            ),
          ],
        ),
      );
    }


    // Convert to basic chart data format
    final chartData = _moodData.asMap().entries.map((entry) {
      return {
        'x': entry.key.toDouble(),
        'y': entry.value.mood,
        'date': entry.value.date,
        'note': entry.value.note,
      };
    }).toList();

    if (chartData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTokens.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTokens.borderLight,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_neutral,
                color: AppTokens.iconPrimary,
                size: 44,
              ),
              const SizedBox(height: 10),
              Text(
                'No mood data available for this period',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTokens.textPrimary,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use simple Cristalyse chart
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTokens.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTokens.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _getChartDescription(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: AppTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visualize how your mood has changed over time',
            style: TextStyle(
              color: AppTokens.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 200,
            child: CristalyseChart()
                .data(chartData)
                .mapping(x: 'x', y: 'y')
                .geomLine(strokeWidth: 3.0)
                .geomPoint(size: 8.0)
                .scaleXContinuous()
                .scaleYContinuous(
                  min: 0.5,
                  max: 5.5,
                )
                .theme(ChartTheme.defaultTheme().copyWith(
                  primaryColor: AppColors.pink100,
                  colorPalette: [AppColors.pink100, AppColors.strongGreen],
                ))
                .build(),
          ),
          const SizedBox(height: 12),
          // Axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.pink100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Y-axis: Mood Level (1-5)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTokens.textSecondary,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppTokens.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'X-axis: ${_getXAxisLabel()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTokens.textSecondary,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getXAxisLabel() {
    switch (widget.timeRange) {
      case 'week':
        return 'Days';
      case 'month':
        return 'Days';
      case 'year':
        return 'Months';
      default:
        return 'Time';
    }
  }

  ChartTimeRange? _getChartTimeRange() {
    switch (widget.timeRange) {
      case 'day':
        return ChartTimeRange.day;
      case 'month':
        return ChartTimeRange.month;
      case 'year':
        return ChartTimeRange.year;
      default:
        return null; // 'week' is not in the enum
    }
  }

  String _getChartDescription() {
    final chartTimeRange = _getChartTimeRange();
    if (chartTimeRange != null) {
      return WellnessChartFactory.getMoodTrendDescription(
          chartTimeRange, widget.selectedDate);
    }
    // Fallback for 'week' or other unsupported ranges
    return 'Mood Trends Analysis';
  }
}
