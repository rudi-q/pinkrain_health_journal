import 'package:flutter/material.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/util/helpers.dart' show devPrint;
import 'package:cristalyse/cristalyse.dart';
import 'charts/chart_data_models.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 40),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[300]),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadMoodData,
                child: Text('Retry'),
              ),
            ],
          ),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_neutral, color: Colors.grey[400], size: 40),
              const SizedBox(height: 10),
              Text(
                'No mood data available for this period',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Use simple Cristalyse chart
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
            'Mood Trends',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getChartDescription(),
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
                .geomLine(strokeWidth: 3.0)
                .geomPoint(size: 8.0)
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

  String _getChartDescription() {
    switch (widget.timeRange) {
      case 'day':
        return 'Your mood for ${_formatDate(widget.selectedDate)}';
      case 'month':
        return 'Your daily mood trends for ${_formatMonth(widget.selectedDate)}';
      case 'year':
        return 'Your monthly mood trends for ${widget.selectedDate.year}';
      default:
        return 'Your mood trends';
    }
  }

  String _formatDate(DateTime date) {
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

  String _formatMonth(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
