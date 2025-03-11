import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/core/util/helpers.dart' show devPrint;

// Define a typedef for the mood data fetcher function
typedef MoodDataFetcher = Future<Map<String, dynamic>?> Function(DateTime date);

class MoodTrendChart extends StatefulWidget {
  final String timeRange;
  final DateTime selectedDate;
  final MoodDataFetcher? moodDataFetcher;

  MoodTrendChart({
    Key? key,
    required this.timeRange,
    DateTime? selectedDate,
    this.moodDataFetcher,
  }) : selectedDate = selectedDate ?? DateTime.now(),
       super(key: key);

  @override
  State<MoodTrendChart> createState() => _MoodTrendChartState();
}

class _MoodTrendChartState extends State<MoodTrendChart> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<FlSpot> _moodData = [];
  double _minY = 1;
  double _maxY = 5;
  double _minX = 0;
  double _maxX = 30;

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
      
      // Calculate min and max values for Y axis (mood values)
      double minY = 5;
      double maxY = 1;
      
      for (var spot in moodData) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
      }
      
      // Set min and max for X axis (time periods)
      double maxX = moodData.length - 1.0;
      
      setState(() {
        _moodData = moodData;
        _minY = minY > 0 ? minY - 0.5 : 1;
        _maxY = maxY < 5 ? maxY + 0.5 : 5;
        _minX = 0;
        _maxX = maxX;
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

  Future<List<FlSpot>> _generateMoodData() async {
    List<FlSpot> spots = [];
    final referenceDate = widget.selectedDate;
    
    try {
      switch (widget.timeRange) {
        case 'day':
          // Generate hourly data for a day
          final startOfDay = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
          
          // For day view, we'll check if there's a mood entry for this day
          final moodData = await (widget.moodDataFetcher ?? HiveService.getMoodForDate)(startOfDay);
          
          if (moodData != null && moodData.containsKey('mood')) {
            // If we have mood data for this day, create a single spot
            spots.add(FlSpot(12, moodData['mood'].toDouble())); // Position at noon
          }
          
          break;
          
        case 'month':
          // Generate daily data for a month
          final startOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
          final daysInMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0).day;
          
          for (int day = 0; day < daysInMonth; day++) {
            final date = startOfMonth.add(Duration(days: day));
            final moodData = await (widget.moodDataFetcher ?? HiveService.getMoodForDate)(date);
            
            if (moodData != null && moodData.containsKey('mood')) {
              spots.add(FlSpot(day.toDouble(), moodData['mood'].toDouble()));
            }
          }
          
          break;
          
        case 'year':
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
              spots.add(FlSpot(month.toDouble(), totalMood / moodCount));
            }
          }
          
          break;
          
        default:
          devPrint('Invalid time range: ${widget.timeRange}');
      }
      
      return spots;
    } catch (e) {
      devPrint('Error generating mood data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getChartDescription(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 15),
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_hasError)
          Center(
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
          )
        else if (_moodData.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
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
          )
        else
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 0, top: 16, bottom: 16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
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
                        interval: _getInterval(),
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text(
                              _getBottomTitle(value),
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          String text = '';
                          switch (value.toInt()) {
                            case 1:
                              text = 'Very Bad';
                              break;
                            case 2:
                              text = 'Bad';
                              break;
                            case 3:
                              text = 'Neutral';
                              break;
                            case 4:
                              text = 'Good';
                              break;
                            case 5:
                              text = 'Great';
                              break;
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 70,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Color(0xff37434d), width: 1),
                  ),
                  minX: _minX,
                  maxX: _maxX,
                  minY: _minY,
                  maxY: _maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _moodData,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.5),
                          Theme.of(context).primaryColor,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.3),
                            Theme.of(context).primaryColor.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
    final yesterday = today.subtract(Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatMonth(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  double _getInterval() {
    switch (widget.timeRange) {
      case 'day':
        return 4; // Every 4 hours
      case 'month':
        return 5; // Every 5 days
      case 'year':
        return 1; // Every month
      default:
        return 1;
    }
  }

  String _getBottomTitle(double value) {
    switch (widget.timeRange) {
      case 'day':
        // For day view, show hours
        final hour = value.toInt();
        if (hour == 0) return '12 AM';
        if (hour == 12) return '12 PM';
        if (hour < 12) return '$hour AM';
        return '${hour - 12} PM';
        
      case 'month':
        // For month view, show days
        return '${value.toInt() + 1}';
        
      case 'year':
        // For year view, show months
        final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
        return months[value.toInt()];
        
      default:
        return '';
    }
  }
}
