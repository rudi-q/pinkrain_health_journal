import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/theme/colors.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'package:pinkrain/features/journal/presentation/journal_notifier.dart';

/// Data class to hold insight information
class InsightData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isPositive;

  const InsightData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isPositive = true,
  });
}

class PersonalizedInsights extends ConsumerStatefulWidget {
  final String timeRange; // 'week', 'month', or 'year'
  final DateTime selectedDate;

  const PersonalizedInsights({
    super.key,
    required this.timeRange,
    required this.selectedDate,
  });

  @override
  ConsumerState<PersonalizedInsights> createState() => _PersonalizedInsightsState();
}

class _PersonalizedInsightsState extends ConsumerState<PersonalizedInsights> {
  List<InsightData> _insights = [];
  bool _isLoading = true;
  int _totalDataPoints = 0;
  
  /// Generation token to prevent race conditions in async insight analysis.
  /// Incremented at the start of each invocation; only the run whose local
  /// token matches the current _insightGeneration may update state.
  int _insightGeneration = 0;

  @override
  void initState() {
    super.initState();
    _analyzeAndGenerateInsights();
  }

  @override
  void didUpdateWidget(PersonalizedInsights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange ||
        oldWidget.selectedDate != widget.selectedDate) {
      _analyzeAndGenerateInsights();
    }
  }

  /// Get the start date based on time range and selected date
  DateTime _getStartDate() {
    final date = widget.selectedDate;
    switch (widget.timeRange) {
      case 'week':
        final weekday = date.weekday;
        return DateTime(date.year, date.month, date.day)
            .subtract(Duration(days: weekday - 1));
      case 'month':
        return DateTime(date.year, date.month, 1);
      case 'year':
        return DateTime(date.year, 1, 1);
      default:
        return date.subtract(const Duration(days: 7));
    }
  }

  /// Get the end date based on time range and selected date
  DateTime _getEndDate() {
    final date = widget.selectedDate;
    switch (widget.timeRange) {
      case 'week':
        final weekday = date.weekday;
        final startOfWeek = DateTime(date.year, date.month, date.day)
            .subtract(Duration(days: weekday - 1));
        return startOfWeek.add(const Duration(days: 6));
      case 'month':
        return DateTime(date.year, date.month + 1, 0); // Last day of month
      case 'year':
        return DateTime(date.year, 12, 31);
      default:
        return date;
    }
  }

  /// Analyze user data and generate personalized insights
  Future<void> _analyzeAndGenerateInsights() async {
    // Increment generation token BEFORE any async work to mark this as the latest run
    _insightGeneration++;
    final localGeneration = _insightGeneration;
    
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final insights = <InsightData>[];
    final endDate = _getEndDate();
    final startDate = _getStartDate();
    int dataPoints = 0;

    try {
      // Analyze mood patterns
      final moodAnalysis = await _analyzeMoodPatterns(startDate, endDate);
      insights.addAll(moodAnalysis['insights'] as List<InsightData>);
      dataPoints += moodAnalysis['dataPoints'] as int;

      // Analyze medication adherence impact
      final medAnalysis = await _analyzeMedicationImpact(startDate, endDate);
      insights.addAll(medAnalysis['insights'] as List<InsightData>);
      dataPoints += medAnalysis['dataPoints'] as int;

      // Analyze symptom patterns
      final symptomAnalysis = await _analyzeSymptomPatterns(startDate, endDate);
      insights.addAll(symptomAnalysis['insights'] as List<InsightData>);
      dataPoints += symptomAnalysis['dataPoints'] as int;

      // If no insights generated, show empty state message
      if (insights.isEmpty) {
        insights.add(InsightData(
          title: 'Keep logging your wellness',
          description: 'Continue tracking your mood and medications to unlock personalized insights about your patterns.',
          icon: Icons.auto_awesome,
          color: AppColors.pink100,
        ));
      }

      // Only update state if this is still the latest generation and widget is mounted
      if (!mounted || localGeneration != _insightGeneration) return;
      setState(() {
        _insights = insights;
        _totalDataPoints = dataPoints;
        _isLoading = false;
      });
    } catch (e) {
      // Only update state if this is still the latest generation and widget is mounted
      if (!mounted || localGeneration != _insightGeneration) return;
      setState(() {
        _insights = [
          InsightData(
            title: 'Unable to analyze data',
            description: 'There was an issue analyzing your data. Please try again later.',
            icon: Icons.error_outline,
            color: AppColors.pastelRed,
            isPositive: false,
          ),
        ];
        _isLoading = false;
      });
    }
  }

  /// Analyze mood patterns from stored data
  Future<Map<String, dynamic>> _analyzeMoodPatterns(
      DateTime startDate, DateTime endDate) async {
    final insights = <InsightData>[];
    int dataPoints = 0;

    // Collect mood data
    final moodByDay = <int, List<int>>{}; // weekday -> list of moods
    final allMoods = <int>[];

    // Batch load mood entries to avoid slow sequential disk reads
    const int batchSize = 60; // prevent overwhelming IO for long ranges
    final dates = <DateTime>[];
    for (DateTime date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))) {
      dates.add(date);
    }

    for (int i = 0; i < dates.length; i += batchSize) {
      final batchDates = dates.sublist(i, i + batchSize > dates.length ? dates.length : i + batchSize);
      final batchResults = await Future.wait(
        batchDates.map((date) => HiveService.getMoodForDate(date)),
      );

      for (int j = 0; j < batchDates.length; j++) {
        final date = batchDates[j];
        final moodData = batchResults[j];
        if (moodData != null && moodData.containsKey('mood')) {
          final mood = moodData['mood'] as int;
          allMoods.add(mood);
          dataPoints++;

          moodByDay.putIfAbsent(date.weekday, () => []).add(mood);
        }
      }
    }

    if (allMoods.isEmpty) {
      return {'insights': insights, 'dataPoints': dataPoints};
    }

    // Calculate average mood
    final avgMood = allMoods.reduce((a, b) => a + b) / allMoods.length;

    // Find best and worst days of week
    double bestDayAvg = 0;
    double worstDayAvg = 5;
    int bestDay = 1;
    int worstDay = 1;

    for (var entry in moodByDay.entries) {
      if (entry.value.isNotEmpty) {
        final dayAvg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        if (dayAvg > bestDayAvg) {
          bestDayAvg = dayAvg;
          bestDay = entry.key;
        }
        if (dayAvg < worstDayAvg) {
          worstDayAvg = dayAvg;
          worstDay = entry.key;
        }
      }
    }

    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    // Generate mood pattern insights
    if (moodByDay.length >= 3 && bestDayAvg > avgMood + 0.3) {
      insights.add(InsightData(
        title: 'Your best day is ${dayNames[bestDay]}',
        description: 'Your mood tends to be highest on ${dayNames[bestDay]}s. Consider what makes this day special.',
        icon: Icons.sentiment_very_satisfied,
        color: AppColors.pastelGreen,
      ));
    }

    if (moodByDay.length >= 3 && worstDayAvg < avgMood - 0.3 && bestDay != worstDay) {
      insights.add(InsightData(
        title: '${dayNames[worstDay]}s may need extra care',
        description: 'Your mood tends to dip on ${dayNames[worstDay]}s. Try scheduling self-care activities.',
        icon: Icons.self_improvement,
        color: AppColors.pastelPurple,
        isPositive: false,
      ));
    }

    // Mood trend insight
    if (allMoods.length >= 5) {
      final firstHalf = allMoods.sublist(0, allMoods.length ~/ 2);
      final secondHalf = allMoods.sublist(allMoods.length ~/ 2);
      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      if (secondAvg > firstAvg + 0.3) {
        insights.add(InsightData(
          title: 'Your mood is improving',
          description: 'Great progress! Your average mood has increased over this period.',
          icon: Icons.trending_up,
          color: AppColors.pastelGreen,
        ));
      } else if (secondAvg < firstAvg - 0.3) {
        insights.add(InsightData(
          title: 'Your mood may need attention',
          description: 'Your mood has been trending lower. Consider trying new wellness activities.',
          icon: Icons.trending_down,
          color: AppColors.pastelOrange,
          isPositive: false,
        ));
      }
    }

    return {'insights': insights, 'dataPoints': dataPoints};
  }

  /// Analyze medication adherence and its impact on mood
  Future<Map<String, dynamic>> _analyzeMedicationImpact(
      DateTime startDate, DateTime endDate) async {
    final insights = <InsightData>[];
    int dataPoints = 0;

    // Use the same data source as the Medication Adherence card
    final journalLog = ref.read(pillIntakeProvider.notifier).journalLog;
    final adherenceRate = await journalLog.getAdherenceRateAllAsync(startDate, endDate);
    final avgAdherence = adherenceRate * 100; // Convert to percentage
    
    // Count data points (days with medication logs)
    // Batch load medication logs to avoid slow sequential disk reads
    const int batchSize = 60; // prevent overwhelming IO for long ranges
    final dates = <DateTime>[];
    for (DateTime date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))) {
      dates.add(date);
    }

    for (int i = 0; i < dates.length; i += batchSize) {
      final batchDates = dates.sublist(
          i, i + batchSize > dates.length ? dates.length : i + batchSize);
      final batchResults = await Future.wait(
        batchDates.map((date) => HiveService.getMedicationLogsForDate(date)),
      );

      for (final medicationLogs in batchResults) {
        if (medicationLogs != null && medicationLogs.isNotEmpty) {
          dataPoints++;
        }
      }
    }

    // Get correlation data for mood-adherence comparison
    final correlationData = await HiveService.getMedicationMoodCorrelation(
      startDate: startDate,
      endDate: endDate,
    );

    // Analyze mood differences between high and low adherence days
    if (correlationData.length >= 3) {
      final highAdherenceMoods = <double>[];
      final lowAdherenceMoods = <double>[];

      for (var point in correlationData) {
        final adherence = point['x'] as double;
        final mood = point['y'] as double;
        
        if (adherence >= 80) {
          highAdherenceMoods.add(mood);
        } else if (adherence < 50) {
          lowAdherenceMoods.add(mood);
        }
      }

      if (highAdherenceMoods.isNotEmpty && lowAdherenceMoods.isNotEmpty) {
        final highAvg = highAdherenceMoods.reduce((a, b) => a + b) / highAdherenceMoods.length;
        final lowAvg = lowAdherenceMoods.reduce((a, b) => a + b) / lowAdherenceMoods.length;

        if (highAvg > lowAvg + 0.5) {
          String description;
          if (lowAvg == 0) {
            // Avoid division by zero - show absolute point improvement instead
            final pointImprovement = (highAvg - lowAvg).toStringAsFixed(1);
            description = 'Your mood is $pointImprovement points better on days with good medication adherence.';
          } else {
            final improvement = ((highAvg - lowAvg) / lowAvg * 100).toStringAsFixed(0);
            description = 'Your mood is ~$improvement% better on days with good medication adherence.';
          }
          insights.add(InsightData(
            title: 'Medications are helping',
            description: description,
            icon: Icons.medication,
            color: AppColors.pastelGreen,
          ));
        }
      }
    }

    // Generate adherence-based insights (only if we have medication data)
    if (dataPoints > 0 || adherenceRate > 0) {
      if (avgAdherence >= 90) {
        insights.add(InsightData(
          title: 'Excellent medication consistency',
          description: 'You\'re maintaining ${avgAdherence.toStringAsFixed(0)}% adherence this ${widget.timeRange}. Great job!',
          icon: Icons.verified,
          color: AppColors.pastelBlue,
        ));
      } else if (avgAdherence >= 70) {
        insights.add(InsightData(
          title: 'Good medication adherence',
          description: 'Your ${widget.timeRange}ly adherence is ${avgAdherence.toStringAsFixed(0)}%. Keep it up!',
          icon: Icons.thumb_up,
          color: AppColors.pastelGreen,
        ));
      } else if (avgAdherence >= 60) {
        insights.add(InsightData(
          title: 'Moderate medication adherence',
          description: 'Your ${widget.timeRange}ly adherence is ${avgAdherence.toStringAsFixed(0)}%. A few more consistent days will move you up.',
          icon: Icons.stacked_line_chart,
          color: AppColors.pastelYellow,
        ));
      } else if (avgAdherence < 60) {
        insights.add(InsightData(
          title: 'Room for improvement',
          description: 'Your ${widget.timeRange}ly adherence is ${avgAdherence.toStringAsFixed(0)}%. Setting reminders could help.',
          icon: Icons.alarm,
          color: AppColors.pastelOrange,
          isPositive: false,
        ));
      }
    }

    return {'insights': insights, 'dataPoints': dataPoints};
  }

  /// Analyze symptom patterns
  Future<Map<String, dynamic>> _analyzeSymptomPatterns(
      DateTime startDate, DateTime endDate) async {
    final insights = <InsightData>[];
    int dataPoints = 0;

    // Get symptom entries
    final symptomEntries = await HiveService.getSymptomEntries(startDate, endDate);
    dataPoints = symptomEntries.length;

    if (symptomEntries.isEmpty) {
      return {'insights': insights, 'dataPoints': dataPoints};
    }

    // Count symptom frequencies
    final symptomCounts = <String, int>{};
    for (var entry in symptomEntries) {
      for (var symptom in entry.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
    }

    if (symptomCounts.isEmpty) {
      return {'insights': insights, 'dataPoints': dataPoints};
    }

    // Find most common symptom
    final sortedSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedSymptoms.isNotEmpty && sortedSymptoms.first.value >= 2) {
      final topSymptom = sortedSymptoms.first;
      final percentage = (topSymptom.value / symptomEntries.length * 100).toStringAsFixed(0);
      
      insights.add(InsightData(
        title: '${topSymptom.key} is your top symptom',
        description: 'You\'ve logged ${topSymptom.key.toLowerCase()} on $percentage% of days.',
        icon: Icons.medical_information,
        color: AppColors.pastelPurple,
        isPositive: false,
      ));
    }

    return {'insights': insights, 'dataPoints': dataPoints};
  }

  @override
  Widget build(BuildContext context) {
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
            'Your Personalized Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: AppTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Description
          Text(
            'Data-driven recommendations tailored to your wellness patterns',
            style: TextStyle(
              color: AppTokens.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // Insight cards
            ..._insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsightCard(insight: insight),
                )),
            const SizedBox(height: 8),
            // Data points info
            if (_totalDataPoints > 0)
              Text(
                'Based on $_totalDataPoints data points from your ${widget.timeRange}ly tracking',
                style: TextStyle(
                  color: AppTokens.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              )
            else
              Text(
                'Start logging to receive personalized insights',
                style: TextStyle(
                  color: AppTokens.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final InsightData insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.color.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTokens.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              insight.icon,
              color: insight.isPositive ? AppColors.strongGreen : AppColors.pastelOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Outfit',
                    color: AppTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    color: AppTokens.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
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
