import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/core/widgets/bottom_navigation.dart';
import 'package:pinkrain/features/journal/presentation/journal_notifier.dart';
import 'package:pinkrain/features/wellness/domain/share_as_pdf.dart';
// MoodTracker removed - now using HiveService for real data
import 'package:pinkrain/features/wellness/presentation/components/personalized_insights.dart';
import 'package:pinkrain/features/wellness/presentation/wellness_notifier.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/icons.dart';
import '../../../core/theme/tokens.dart';
import 'components/mood_trend_chart.dart';
import 'components/scatter_plot_painter.dart';
// import 'components/wellness_prediction.dart'; // Commented out with Mood Forecast

//todo: Implement wellness data persistence and analytics

class WellnessTrackerScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const WellnessTrackerScreen({
    super.key,
    this.initialDate,
  });

  @override
  ConsumerState<WellnessTrackerScreen> createState() =>
      WellnessTrackerScreenState();
}

class WellnessTrackerScreenState extends ConsumerState<WellnessTrackerScreen> {
  int _selectedMood = -1; // -1 means no mood selected
  String _selectedDateOption = 'week';
  late DateTime _selectedDate;
  late WellnessScreenNotifier wellnessNotifier;

  final GlobalKey _printableWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    wellnessNotifier = ref.read(wellnessScreenProvider.notifier);
    // Load mood data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoodForSelectedDate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We'll handle mood loading when the selected date changes
  }

  @override
  void didUpdateWidget(WellnessTrackerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // We'll handle mood loading when the selected date changes
  }

  // Format the selected date based on the current view
  String get formattedSelectedDate {
    switch (_selectedDateOption) {
      case 'week':
        // Get start and end of week (Monday to Sunday)
        final startOfWeek = _getStartOfWeek(_selectedDate);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (startOfWeek.month == endOfWeek.month) {
          return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('d, yyyy').format(endOfWeek)}';
        } else {
          return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
        }
      case 'month':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'year':
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  // Get the start of the week (Monday) for a given date
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final daysToSubtract = weekday - 1; // Days to subtract to get to Monday
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  // Navigate to previous period based on current view
  void _navigateToPrevious() {
    switch (_selectedDateOption) {
      case 'week':
        wellnessNotifier
            .setDate(_selectedDate.subtract(const Duration(days: 7)));
        break;
      case 'month':
        wellnessNotifier.setDate(DateTime(
          _selectedDate.year,
          _selectedDate.month - 1,
          _selectedDate.day,
        ));
        break;
      case 'year':
        wellnessNotifier.setDate(DateTime(
          _selectedDate.year - 1,
          _selectedDate.month,
          _selectedDate.day,
        ));
        break;
    }
    // Log the navigation for debugging
    "Navigated to previous $_selectedDateOption: $formattedSelectedDate".log();
  }

  // Navigate to next period based on current view
  void _navigateToNext() {
    final now = DateTime.now();
    final nextDate = switch (_selectedDateOption) {
      'week' => _selectedDate.add(const Duration(days: 7)),
      'month' => DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          _selectedDate.day,
        ),
      'year' => DateTime(
          _selectedDate.year + 1,
          _selectedDate.month,
          _selectedDate.day,
        ),
      _ => _selectedDate,
    };

    // Only allow navigation up to the current date
    if (!nextDate.isAfter(now)) {
      wellnessNotifier.setDate(nextDate);
      "Navigated to next $_selectedDateOption: $formattedSelectedDate".log();
    } else {
      "Cannot navigate to future dates".log();
    }
  }

  // Load the mood data for the selected date
  Future<void> _loadMoodForSelectedDate() async {
    if (_selectedDateOption == 'week') {
      // For week view, we don't need to load a specific mood
      // The mood data will be shown in the chart/aggregated view
      setState(() {
        _selectedMood = -1;
      });
    }
  }

  /// Get mood counts for the current date range from HiveService
  Future<Map<int, int>> _getMoodCountsForRange() async {
    final Map<int, int> moodCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    DateTime startDate;
    DateTime endDate = _selectedDate;
    
    switch (_selectedDateOption) {
      case 'week':
        startDate = _getStartOfWeek(_selectedDate);
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'month':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        break;
      case 'year':
        startDate = DateTime(_selectedDate.year, 1, 1);
        endDate = DateTime(_selectedDate.year, 12, 31);
        break;
      default:
        startDate = _selectedDate;
    }
    
    // Collect all date futures and await them in batch
    final futures = <Future<Map<String, dynamic>?>>[];
    
    for (DateTime date = startDate; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
      futures.add(HiveService.getMoodForDate(date));
    }
    
    // Await all futures in parallel
    final results = await Future.wait(futures);
    
    // Aggregate counts from the completed results
    for (final moodData in results) {
      if (moodData != null && moodData.containsKey('mood')) {
        final mood = moodData['mood'] as int;
        if (mood >= 1 && mood <= 5) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }
      }
    }
    
    return moodCounts;
  }

  /// Calculate Pearson correlation coefficient from data points
  double _calculateCorrelation(List<Map<String, dynamic>> data) {
    if (data.length < 2) return 0.0;
    
    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
    
    for (var point in data) {
      final x = point['x'] as double;
      final y = point['y'] as double;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
    }
    
    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator = ((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    
    if (denominator <= 0) return 0.0;
    
    return numerator / math.sqrt(denominator);
  }

  /// Get correlation description based on the correlation value
  Map<String, String> _getCorrelationDescription(double correlation, int dataPoints) {
    if (dataPoints < 3) {
      return {
        'title': 'Not enough data',
        'description': 'Log more mood entries with medications\nto see correlation insights',
      };
    }
    
    final absCorrelation = correlation.abs();
    String strength;
    String direction = correlation >= 0 ? 'positive' : 'negative';
    
    if (absCorrelation >= 0.7) {
      strength = 'Strong';
    } else if (absCorrelation >= 0.4) {
      strength = 'Moderate';
    } else if (absCorrelation >= 0.2) {
      strength = 'Weak';
    } else {
      return {
        'title': 'No clear correlation',
        'description': 'Your mood doesn\'t show a clear\npattern with medication adherence',
      };
    }
    
    String description;
    if (correlation >= 0.4) {
      description = 'Taking medications regularly\nis associated with better\nmood scores';
    } else if (correlation >= 0.2) {
      description = 'There may be a slight link\nbetween medication adherence\nand improved mood';
    } else if (correlation <= -0.4) {
      description = 'An unexpected pattern detected.\nConsider discussing with\nyour healthcare provider';
    } else {
      description = 'Continue tracking to get\nmore accurate insights';
    }
    
    return {
      'title': '$strength $direction correlation',
      'description': description,
    };
  }

  @override
  Widget build(BuildContext context) {
    final previousDate = _selectedDate;
    _selectedDate = ref.watch(wellnessScreenProvider);

    // Load mood data when the selected date changes
    if (previousDate != _selectedDate && _selectedDateOption == 'week') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMoodForSelectedDate();
      });
    }


    return Scaffold(
      backgroundColor: AppTokens.bgPrimary,
      appBar: AppBar(
        title: const Text(
          'Wellness',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTokens.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTokens.bgPrimary,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () {
              context.go('/profile');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.buttonElevatedBg,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                size: 24,
                strokeWidth: 1,
                color: AppTokens.iconPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                    // Week/Month/Year selector
                    Center(
                      child: _buildDateRangeSelector(),
                    ),
                    const SizedBox(height: 30),

                // Wellness title and description
            RepaintBoundary(
              key: _printableWidgetKey,
              child: Column(
                children: [
                Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BlurText(
                          key: ValueKey(_selectedDate.getNameOf(_selectedDateOption)),
                          text:
                              "${_selectedDate.getNameOf(_selectedDateOption)}'s Wellness Report",
                          duration: const Duration(milliseconds: 800),
                          type: AnimationType.word,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 3),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            color: Theme.of(context).colorScheme.primary,
                            size: IconTheme.of(context).size! * 0.7,
                          ), onPressed: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              devPrint("Height: ${_printableWidgetKey.currentContext!.size!.height}");
                              captureAndShareAsPdfWidget(_printableWidgetKey, 'PinkRain_${_selectedDate.getNameOf(_selectedDateOption)}_Wellness_Report');
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Track your journey and nurture your whole self - mind and body together.',
                      style: TextStyle(
                        color: AppTokens.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Mood tracker
                  BlurText(
                    key: ValueKey('$_selectedDateOption: $_selectedDate'),
                    text: wellnessNotifier.checkInMessage(_selectedDateOption),
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  FutureBuilder<Map<int, int>>(
                    future: _getMoodCountsForRange(),
                    builder: (context, snapshot) {
                      final moodCounts = snapshot.data ?? {};
                      final totalMoods = moodCounts.values.fold(0, (sum, count) => sum + count);
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (index) => _moodIcon(
                            index: index,
                            moodCount: moodCounts[index + 1] ?? 0,
                            totalMoods: totalMoods > 0 ? totalMoods : 1,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                 

                  const SizedBox(height: 30),

                  // Medication adherence
                  _buildMedicationAdherenceCard(),

                  const SizedBox(height: 30),
                  // Missed dose patterns
                  buildMissedDosagePatterns(),

                  const SizedBox(height: 30),

                  // Active symptoms and triggers
                  buildSymptomsAndTriggers(),

                  const SizedBox(height: 30),

                  // Medication impact
                  _buildMedicationImpactCard(),
                  const SizedBox(height: 30),

                  // NEW SECTION: Mood Trend Chart
                  SizedBox(
                    width: double.infinity,
                    child: MoodTrendChart(
                      timeRange: _selectedDateOption,
                      selectedDate: _selectedDate,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // SECTION: Correlation Analysis
       /*           BlurText(
                    text: 'Wellness Factor Analysis',
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ChimeBellText(
                    text:
                        'Discover which factors most strongly influence your mood',
                    duration: const Duration(milliseconds: 50),
                    textStyle: TextStyle(
                      color: AppTokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const SizedBox(
                    width: double.infinity,
                    child: CorrelationAnalysis(),
                  ),
                  const SizedBox(height: 30),*/

                  /* BlurText(
                    text: 'Mood Forecast',
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ChimeBellText(
                    text:
                        'AI-powered prediction of your mood trends (Coming soon, for illustration purposes only)',
                    duration: const Duration(milliseconds: 50),
                    textStyle: TextStyle(
                      color: AppTokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const SizedBox(
                    width: double.infinity,
                    child: WellnessPrediction(),
                  ),
                  const SizedBox(height: 50), */


                  // NEW SECTION: Personalized Insights
                  SizedBox(
                    width: double.infinity,
                    child: PersonalizedInsights(
                      timeRange: _selectedDateOption,
                      selectedDate: _selectedDate,
                    ),
                  ),
                  const SizedBox(height: 30),


                  const SizedBox(height: 30),

                  const SizedBox(height: 10),
                    const SizedBox(height: 80), // Space for floating tabs
                  ],
                ),
              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Date navigation controls above bottom navigation bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Builder(
                builder: (context) {
                  final isSelectedDateToday = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                  ).isSameDate(DateTime.now());
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          size: 24,
                          strokeWidth: 1,
                          color: AppTokens.iconPrimary,
                        ),
                        onPressed: _navigateToPrevious,
                      ),
                      Text(
                        formattedSelectedDate,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Next button
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 24,
                          strokeWidth: 1,
                          color: isSelectedDateToday
                              ? AppTokens.iconMuted
                              : AppTokens.iconPrimary,
                        ),
                        onPressed: isSelectedDateToday ? null : _navigateToNext,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          buildBottomNavigationBar(context: context, currentRoute: 'wellness'),
    );
  }

  Widget _buildDateRangeSelector() {
    final options = ['week', 'month', 'year'];
    final selectedIndex = options.indexOf(_selectedDateOption);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pink5,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTokens.borderLight,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            left: selectedIndex * 80.0,
            top: 4,
            bottom: 4,
            child: Container(
              width: 80.0,
              decoration: BoxDecoration(
                color: AppTokens.buttonPrimaryBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pink40.withAlpha(40),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Tab buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) => _dateOption(option)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dateOption(String text) {
    final isSelected = _selectedDateOption == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDateOption = text;
        });
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          text.capitalize(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTokens.textPrimary : AppTokens.textSecondary,
            fontWeight: isSelected ? AppTokens.fontWeightBold : AppTokens.fontWeightW500,
            fontSize: 14,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }

  Widget _moodIcon({required int index, int intensity = 500, int moodCount = 0, int totalMoods = 1}) {
    bool isSelected = _selectedMood == index;

    // For week/month/year view, show aggregated data
    if (_selectedDateOption == 'week' || _selectedDateOption == 'month' || _selectedDateOption == 'year') {
      isSelected = true;
      // Calculate intensity based on mood count ratio
      if (totalMoods > 0 && moodCount > 0) {
        intensity = 100 + ((moodCount / totalMoods) * 800).toInt();
        intensity = intensity.clamp(100, 900).toInt();
        intensity -= intensity % 100;
      } else {
        intensity = 100; // Muted when no data
      }
    } else {
      intensity -= intensity % 100;
    }

    // Return the default visualization for non-day views
    return GestureDetector(
      onTap: () {
        // Week view doesn't support individual mood selection
        // Moods are shown in aggregated view
      },
      child: SvgPicture.asset(
        'assets/icons/${_getMoodIconName(index)}.svg',
        width: 50,
        height: 50,
        colorFilter: _getMoodIconColorFilter(isSelected, intensity: intensity),
      ),
    );
  }

  /// Returns the appropriate ColorFilter for mood icons based on selection state and intensity
  ColorFilter _getMoodIconColorFilter(bool isSelected, {int intensity = 500}) {
    if (isSelected && intensity >= 500) {
      return ColorFilter.mode(
        AppColors.pink100,
        BlendMode.srcIn,
      );
    }
    return ColorFilter.mode(
      AppColors.black40,
      BlendMode.srcIn,
    );
  }

  String _getMoodIconName(int mood) {
    switch (mood) {
      case 0:
        return 'very-sad';
      case 1:
        return 'sad';
      case 2:
        return 'neutral';
      case 3:
        return 'happy';
      case 4:
        return 'very-happy';
      default:
        return 'neutral';
    }
  }

  Widget _dayIndicator(String day, bool isComplete) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(
            color: AppTokens.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isComplete ? AppColors.pastelGreen : AppColors.pink100,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _effectivenessBar(String medication, int taken, int scheduled, Color color) {
    // Calculate fill percentage based on taken/scheduled
    final fillPercentage = scheduled > 0 ? taken / scheduled : 0.0;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            medication,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: AppTokens.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              // Background bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.pink5,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Filled portion based on taken/scheduled
              FractionallySizedBox(
                widthFactor: fillPercentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '$taken/$scheduled',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Outfit',
              color: AppTokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build medication impact card with real correlation data
  Widget _buildMedicationImpactCard() {
    // Calculate date range based on selected date option
    DateTime startDate;
    switch (_selectedDateOption) {
      case 'week':
        startDate = _getStartOfWeek(_selectedDate);
        break;
      case 'month':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        break;
      case 'year':
        startDate = DateTime(_selectedDate.year, 1, 1);
        break;
      default:
        startDate = _selectedDate.subtract(const Duration(days: 30));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: HiveService.getMedicationMoodCorrelation(
        startDate: startDate,
        endDate: _selectedDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data ?? [];
        final hasEnoughData = data.length >= 3;

        // Show empty state if not enough data
        if (!hasEnoughData) {
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.pink10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.scatter_plot_outlined,
                    color: Colors.pink[300],
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                const Text(
                  'Medication Impact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: AppTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  'See how your medications affect your mood',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: AppTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // What's needed
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pink5,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'To unlock this insight, you need:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          color: AppTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirementRow(
                        icon: Icons.mood,
                        text: 'Log your mood daily',
                        isComplete: data.isNotEmpty, // Has at least 1 day with both
                      ),
                      const SizedBox(height: 6),
                      _buildRequirementRow(
                        icon: Icons.medication_outlined,
                        text: 'Track medication taken/missed',
                        isComplete: data.isNotEmpty, // Has at least 1 day with both
                      ),
                      const SizedBox(height: 6),
                      _buildRequirementRow(
                        icon: Icons.calendar_today,
                        text: 'At least 3 days with both',
                        isComplete: data.length >= 3,
                      ),
                    ],
                  ),
                ),
                if (data.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${data.length}/3 days tracked',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        
        final correlation = _calculateCorrelation(data);
        final description = _getCorrelationDescription(correlation, data.length);
        
        // Determine icon and color based on correlation
        IconData correlationIcon;
        Color correlationColor;
        
        if (correlation >= 0.4) {
          correlationIcon = Icons.trending_up;
          correlationColor = AppColors.strongGreen;
        } else if (correlation <= -0.4) {
          correlationIcon = Icons.trending_down;
          correlationColor = AppColors.strongRed;
        } else {
          correlationIcon = Icons.trending_flat;
          correlationColor = AppColors.pastelYellow;
        }

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
              const Text(
                'Medication Impact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: AppTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scatter plot
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppColors.pink5,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTokens.borderLight,
                        width: 1,
                      ),
                    ),
                    child: CustomPaint(
                      size: const Size(80, 80),
                      painter: ScatterPlotPainter(correlationData: data),
                    ),
                  ),
                  // Correlation info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              correlationIcon,
                              color: correlationColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                description['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'Outfit',
                                  color: AppTokens.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description['description']!,
                          style: TextStyle(
                            color: AppTokens.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        if (data.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Based on ${data.length} data point${data.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: AppTokens.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper widget for requirement checklist rows
  Widget _buildRequirementRow({
    required IconData icon,
    required String text,
    required bool isComplete,
  }) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isComplete ? AppColors.strongGreen : AppColors.black40,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Outfit',
            ),
          ),
        ),
      ],
    );
  }

  FutureBuilder<Map<String, double>> buildSymptomsAndTriggers() {
    // Calculate date range based on selected date option
    final DateTime startDate = getStartDate(_selectedDateOption, _selectedDate);
    final DateTime endDate = _selectedDate;

    return FutureBuilder<Map<String, double>>(
      future: _calculateSymptomsAndTriggers(startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          // Show empty state when there's no data
          return _buildEmptySymptomsState();
        }

        final data = snapshot.data!;
        final symptoms = data.entries
            .where((e) => _isSymptom(e.key))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final triggers = data.entries
            .where((e) => !_isSymptom(e.key))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Take top 3 symptoms and triggers
        final topSymptoms = symptoms.take(3).toList();
        final topTriggers = triggers.take(3).toList();

        if (topSymptoms.isEmpty && topTriggers.isEmpty) {
          return _buildEmptySymptomsState();
        }

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
              const Text(
                'Active symptoms and triggers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: AppTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              // Symptoms
              if (topSymptoms.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: topSymptoms
                      .map((entry) => _symptomItem(entry.key, entry.value))
                      .toList(),
                ),
              if (topSymptoms.isNotEmpty && topTriggers.isNotEmpty)
                const SizedBox(height: 20),
              // Triggers
              if (topTriggers.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: topTriggers
                      .map((entry) => _triggerItem(entry.key, entry.value))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build empty state for symptoms and triggers section
  Widget _buildEmptySymptomsState() {
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
          const Text(
            'Active symptoms and triggers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: AppTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Empty state content
          Column(
            children: [
              appVectorImage(
                fileName: 'book',
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Add mood notes to see insights',
                style: AppTokens.textStyleSmall.copyWith(
                  fontWeight: AppTokens.fontWeightW600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Identify symptoms and triggers to help you understand your wellness patterns.',
                style: AppTokens.textStyleSmall.copyWith(
                  fontSize: 14,
                  fontWeight: AppTokens.fontWeightW600,
                  color: AppTokens.textPlaceholder,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calculate symptoms and triggers from journal data
  Future<Map<String, double>> _calculateSymptomsAndTriggers(
      DateTime startDate, DateTime endDate) async {
    // Map to track which days each symptom/trigger appeared on
    final Map<String, Set<DateTime>> symptomDays = {};
    final Set<DateTime> daysWithData = {};

    // Build date list once
    final dates = <DateTime>[];
    for (DateTime date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))) {
      dates.add(DateTime(date.year, date.month, date.day));
    }

    // Batch IO to avoid slow per-day round trips
    const int batchSize = 10;
    for (int i = 0; i < dates.length; i += batchSize) {
      final batchDates =
          dates.sublist(i, i + batchSize > dates.length ? dates.length : i + batchSize);

      final moodFutures =
          batchDates.map((date) => HiveService.getMoodEntriesForDate(date)).toList();
      final symptomFutures =
          batchDates.map((date) => HiveService.getSymptomEntries(date, date)).toList();

      final moodResults = await Future.wait(moodFutures);
      final symptomResults = await Future.wait(symptomFutures);

      for (int j = 0; j < batchDates.length; j++) {
        final date = batchDates[j];
        bool hasDataForDay = false;
        final Set<String> foundToday = {};

        final moodEntries = moodResults[j];
        if (moodEntries != null && moodEntries.isNotEmpty) {
          hasDataForDay = true;
          for (var entry in moodEntries) {
            final description = entry['description'] as String? ?? '';
            if (description.isNotEmpty) {
              final extracted = _extractSymptomsAndTriggers(description);
              for (var item in extracted) {
                foundToday.add(item);
              }
            }
          }
        }

        final symptomEntries = symptomResults[j];
        if (symptomEntries.isNotEmpty) {
          hasDataForDay = true;
          for (var entry in symptomEntries) {
            for (var symptom in entry.symptoms) {
              foundToday.add(symptom);
            }
          }
        }

        for (var item in foundToday) {
          symptomDays.putIfAbsent(item, () => {}).add(date);
        }

        if (hasDataForDay) {
          daysWithData.add(date);
        }
      }
    }

    // Convert to frequencies (percentage of days with data)
    final frequencies = <String, double>{};
    final totalDays = daysWithData.length;
    if (totalDays > 0) {
      for (var entry in symptomDays.entries) {
        frequencies[entry.key] = entry.value.length / totalDays;
      }
    }

    return frequencies;
  }

  /// Extract symptoms and triggers from journal description using keyword matching
  List<String> _extractSymptomsAndTriggers(String text) {
    final lowerText = text.toLowerCase();
    final found = <String>[];

    // Negation tokens that indicate a keyword should be skipped
    const negationTokens = {'no', 'not', 'never', 'without', 'none', 'didn\'t', 'don\'t', 'won\'t', 'can\'t', 'couldn\'t'};

    /// Check if a keyword match is negated by looking at preceding text
    bool isNegated(int matchStart, String fullText) {
      // Extract text window before the match (up to ~50 characters or ~3-4 words)
      final windowStart = (matchStart - 50) < 0 ? 0 : matchStart - 50;
      final windowText = fullText.substring(windowStart, matchStart).toLowerCase();
      
      // Tokenize the window and check last 3 words for negation
      final windowWords = windowText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final wordsToCheck = windowWords.length > 3 
          ? windowWords.sublist(windowWords.length - 3)
          : windowWords;
      
      for (final word in wordsToCheck) {
        // Remove punctuation for comparison
        final cleanWord = word.replaceAll(RegExp('[^\\w\']'), '');
        if (cleanWord.isNotEmpty && negationTokens.contains(cleanWord)) {
          return true;
        }
      }
      return false;
    }

    // Symptom keywords
    final symptomKeywords = {
      'headache': 'Headache',
      'head ache': 'Headache',
      'migraine': 'Headache',
      'fatigue': 'Fatigue',
      'tired': 'Fatigue',
      'exhausted': 'Fatigue',
      'exhaustion': 'Fatigue',
      'nausea': 'Nausea',
      'nauseous': 'Nausea',
      'dizzy': 'Dizziness',
      'dizziness': 'Dizziness',
      'pain': 'Pain',
      'ache': 'Pain',
      'sore': 'Pain',
      'fever': 'Fever',
      'chills': 'Chills',
      'cough': 'Cough',
      'congestion': 'Congestion',
      'stuffy': 'Congestion',
    };

    // Trigger keywords
    final triggerKeywords = {
      'stress': 'Stress',
      'stressed': 'Stress',
      'stressing': 'Stress',
      'anxious': 'Stress',
      'anxiety': 'Stress',
      'sleep': 'Poor Sleep',
      'slept': 'Poor Sleep',
      'insomnia': 'Poor Sleep',
      'tossing': 'Poor Sleep',
      'turning': 'Poor Sleep',
      'caffeine': 'Caffeine',
      'coffee': 'Caffeine',
      'tea': 'Caffeine',
      'dehydrated': 'Dehydration',
      'dehydration': 'Dehydration',
      'thirsty': 'Dehydration',
      'screen': 'Screen Time',
      'phone': 'Screen Time',
      'computer': 'Screen Time',
      'exercise': 'Exercise',
      'workout': 'Exercise',
      'gym': 'Exercise',
    };

    // Check for symptoms with word-boundary aware matching
    for (var entry in symptomKeywords.entries) {
      if (found.contains(entry.value)) continue;
      
      // Use regex with word boundaries for whole-word matching
      final pattern = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
      final match = pattern.firstMatch(lowerText);
      
      if (match != null) {
        // Check if negated by examining text before the match
        if (!isNegated(match.start, lowerText)) {
          found.add(entry.value);
        }
      }
    }

    // Check for triggers with word-boundary aware matching
    for (var entry in triggerKeywords.entries) {
      if (found.contains(entry.value)) continue;
      
      // Use regex with word boundaries for whole-word matching
      final pattern = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
      final match = pattern.firstMatch(lowerText);
      
      if (match != null) {
        // Check if negated by examining text before the match
        if (!isNegated(match.start, lowerText)) {
          found.add(entry.value);
        }
      }
    }

    return found;
  }

  /// Check if a keyword represents a symptom (vs trigger)
  bool _isSymptom(String keyword) {
    const symptoms = {
      'Headache',
      'Fatigue',
      'Nausea',
      'Dizziness',
      'Pain',
      'Fever',
      'Chills',
      'Cough',
      'Congestion',
    };
    return symptoms.contains(keyword);
  }

  Widget _symptomItem(String name, double frequency) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.pink5,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.sick,
            color: AppColors.pink100,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: AppTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(frequency * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            color: AppTokens.textSecondary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _triggerItem(String name, double frequency) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.pink10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.warning_amber,
            color: AppColors.pink100,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: AppTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(frequency * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            color: AppTokens.textSecondary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Column buildMissedDosagePatterns() {
    final pillIntakeNotifier = ref.watch(pillIntakeProvider.notifier);
    final missedDays = pillIntakeNotifier.getMissedDoseDays();

    // Format missed days for the summary text
    String summaryText;
    if (missedDays.isEmpty) {
      summaryText = 'Great job! You haven\'t missed any doses recently.';
    } else {
      // Sort days chronologically (Monday = 1, Tuesday = 2, ..., Sunday = 7)
      final dayOrder = {
        'Monday': 1,
        'Tuesday': 2,
        'Wednesday': 3,
        'Thursday': 4,
        'Friday': 5,
        'Saturday': 6,
        'Sunday': 7,
      };
      
      final sortedDays = missedDays.toList()
        ..sort((a, b) => (dayOrder[a] ?? 0).compareTo(dayOrder[b] ?? 0));
      
      final dayNames = sortedDays.map((day) => '${day}s').toList();
      summaryText = 'You tend to miss doses on ${dayNames.join(' and ')}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              const Text(
                'Missed dose patterns',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: AppTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              // Day indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _dayIndicator('Mon', !missedDays.contains('Monday')),
                  _dayIndicator('Tue', !missedDays.contains('Tuesday')),
                  _dayIndicator('Wed', !missedDays.contains('Wednesday')),
                  _dayIndicator('Thu', !missedDays.contains('Thursday')),
                  _dayIndicator('Fri', !missedDays.contains('Friday')),
                  _dayIndicator('Sat', !missedDays.contains('Saturday')),
                  _dayIndicator('Sun', !missedDays.contains('Sunday')),
                ],
              ),
              const SizedBox(height: 20),
              // Summary text
              Center(
                child: Text(
                  summaryText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTokens.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  FutureBuilder<double> _buildMedicationAdherenceCard() {
    String currentTimeFrame = _selectedDate.getNameOf(_selectedDateOption);
    currentTimeFrame = currentTimeFrame == 'today'
        ? 'today'
        : _selectedDateOption == 'week'
            ? 'this week'
            : _selectedDateOption == 'month'
                ? 'this month'
                : 'this year';
    
    // Calculate previous period for comparison
    final DateTime startDate = getStartDate(_selectedDateOption, _selectedDate);
    final DateTime previousStartDate = switch (_selectedDateOption) {
      'week' => startDate.subtract(const Duration(days: 7)),
      'month' => DateTime(_selectedDate.year, _selectedDate.month - 1, 1),
      'year' => DateTime(_selectedDate.year - 1, 1, 1),
      _ => startDate.subtract(const Duration(days: 30)),
    };
    final DateTime previousEndDate = switch (_selectedDateOption) {
      'week' => previousStartDate.add(const Duration(days: 6)),
      'month' => DateTime(_selectedDate.year, _selectedDate.month, 0),
      'year' => DateTime(_selectedDate.year - 1, 12, 31),
      _ => startDate.subtract(const Duration(days: 1)),
    };
    
    final DateTime endDate = _selectedDate;
    final journalLog = ref.read(pillIntakeProvider.notifier).journalLog;

    return FutureBuilder<double>(
      future: journalLog.getAdherenceRateAllAsync(startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTokens.bgElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 15),
                Expanded(child: Text('Loading adherence data...')),
              ],
            ),
          );
        }

        final currentAdherence = snapshot.data ?? 0.0;
        final adherencePercent = (currentAdherence * 100).toStringAsFixed(0);
        
        // Get previous period adherence for comparison
        return FutureBuilder<double>(
          future: journalLog.getAdherenceRateAllAsync(previousStartDate, previousEndDate),
          builder: (context, prevSnapshot) {
            double previousAdherence = 0.0;
            if (prevSnapshot.hasData) {
              previousAdherence = prevSnapshot.data ?? 0.0;
            }
            
            final previousPercent = (previousAdherence * 100).toStringAsFixed(0);
            final isBetter = currentAdherence > previousAdherence;
            final String previousTimeFrame = _selectedDateOption == 'week'
                ? 'last week'
                : _selectedDateOption == 'month'
                    ? 'last month'
                    : 'last year';
            
            final currentText =
                "You've taken $adherencePercent% of your medications $currentTimeFrame";
            final progressText = prevSnapshot.hasData
                ? "${isBetter ? "That's better than" : "That's less than"} $previousTimeFrame ($previousPercent%)"
                : "Keep up the great work!";

            // Get medications for the bars
            final medications = ref.watch(pillIntakeProvider);
            final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
            final journalLogForBars = pillIntakeNotifier.journalLog;

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
                  const Text(
                    'Medication adherence',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: AppTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Circular progress and text
                  Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 50,
                        lineWidth: 8,
                        percent: currentAdherence,
                        center: Text(
                          '$adherencePercent%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'Outfit',
                            color: AppTokens.textPrimary,
                          ),
                        ),
                        progressColor: AppTokens.buttonPrimaryBg,
                        backgroundColor: AppColors.pink10,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Outfit',
                                color: AppTokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              progressText,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTokens.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Medication bars
                  if (medications.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(
                      height: 1,
                      color: AppTokens.borderLight,
                    ),
                    const SizedBox(height: 16),
                    ...medications.map((medication) {
                      final treatment = medication.treatment;
                      final medName = treatment.medicine.name;

                      return FutureBuilder<Map<String, int>>(
                        future: journalLogForBars.getAdherenceCountsAsync(treatment, startDate, endDate),
                        builder: (context, medSnapshot) {
                          if (medSnapshot.connectionState == ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      medName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Outfit',
                                        color: AppTokens.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 3,
                                    child: LinearProgressIndicator(),
                                  ),
                                ],
                              ),
                            );
                          }

                          final counts = medSnapshot.data ?? {'taken': 0, 'scheduled': 0};
                          final taken = counts['taken'] ?? 0;
                          final scheduled = counts['scheduled'] ?? 0;
                          
                          // Calculate adherence rate for color coding
                          final adherenceRate = scheduled > 0 ? taken / scheduled : 0.0;
                          final medRate = adherenceRate * 10;
                          
                          // Use PinkRain colors: pink for lower adherence, green for good adherence
                          final medColor = medRate < 7 
                              ? AppColors.pink100 
                              : AppColors.pastelGreen;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _effectivenessBar(medName, taken, scheduled, medColor),
                          );
                        },
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Temporarily removing the symptom trigger correlations widget until properly implemented
  /*Widget _buildSymptomTriggerCorrelations(SymptomPrediction symptom) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            symptom.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (symptom.triggerCorrelations != null && symptom.triggerCorrelations!.isNotEmpty)
            Column(
              children: symptom.triggerCorrelations!.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }*/

}
