import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/core/widgets/bottom_navigation.dart';
import 'package:pillow/features/journal/presentation/journal_notifier.dart';
import 'package:pillow/features/wellness/domain/share_as_pdf.dart';
import 'package:pillow/features/wellness/domain/wellness_tracker.dart';
import 'package:pillow/features/wellness/presentation/components/correlation_analysis.dart';
import 'package:pillow/features/wellness/presentation/components/mood_painter.dart';
import 'package:pillow/features/wellness/presentation/components/mood_trend_chart.dart';
import 'package:pillow/features/wellness/presentation/components/personalized_insights.dart';
import 'package:pillow/features/wellness/presentation/components/scatter_plot_painter.dart';
import 'package:pillow/features/wellness/presentation/components/wellness_prediction.dart';
import 'package:pillow/features/wellness/presentation/wellness_notifier.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';

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
  String _selectedDateOption = 'month';
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
      case 'day':
        return DateFormat('MMMM d, yyyy').format(_selectedDate);
      case 'month':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'year':
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  // Navigate to previous period based on current view
  void _navigateToPrevious() {
    switch (_selectedDateOption) {
      case 'day':
        wellnessNotifier
            .setDate(_selectedDate.subtract(const Duration(days: 1)));
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
      'day' => _selectedDate.add(const Duration(days: 1)),
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

  // Navigate to today
  void _navigateToToday() {
    wellnessNotifier.setDate(DateTime.now());

    setState(() {
      _selectedDateOption = 'day';
    });
  }

  // Load the mood data for the selected date
  Future<void> _loadMoodForSelectedDate() async {
    if (_selectedDateOption == 'day') {
      // Get mood data for the selected date from HiveService
      final moodData = await HiveService.getMoodForDate(_selectedDate);
      if (moodData != null && mounted) {
        setState(() {
          _selectedMood = moodData['mood'] as int;
        });
      } else {
        // Reset mood if no data found
        setState(() {
          _selectedMood = -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previousDate = _selectedDate;
    _selectedDate = ref.watch(wellnessScreenProvider);

    // Load mood data when the selected date changes
    if (previousDate != _selectedDate && _selectedDateOption == 'day') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMoodForSelectedDate();
      });
    }


    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Date navigation and selector
                Column(
                  children: [
                    // Date navigation controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _navigateToPrevious,
                        ),
                        GestureDetector(
                          onTap: () => _showDatePicker(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formattedSelectedDate,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.calendar_today, size: 16),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Today button
                            TextButton(
                              onPressed: _navigateToToday,
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Today'),
                            ),
                            // Next button
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                              ).isSameDate(DateTime.now())
                                  ? null
                                  : _navigateToNext,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date range selector
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _dateOption('day'),
                            _dateOption('month'),
                            _dateOption('year'),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                              captureAndShareAsPdfWidget(_printableWidgetKey, 'Pillow_${_selectedDate.getNameOf(_selectedDateOption)}_Wellness_Report');
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
                        color: Colors.black54,
                        fontSize: 14,
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
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      5,
                      (index) => _moodIcon(index: index),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // More details button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BlurText(
                        text: 'Want to share more details?',
                        duration: const Duration(milliseconds: 800),
                        type: AnimationType.word,
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Medication adherence
                  BlurText(
                    text: 'Medication adherence',
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildMedicationAdherenceCard(),

                  const SizedBox(height: 15),

                  _medicineAdherenceBar(),

                  const SizedBox(height: 30),
                  // Missed dose patterns
                  buildMissedDosagePatterns(),

                  const SizedBox(height: 30),

                  // Active symptoms and triggers
                  buildSymptomsAndTriggers(),

                  const SizedBox(height: 30),

                  // Medication impact
                  BlurText(
                    text: 'Medication impact',
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: HiveService.getMedicationMoodCorrelation(
                            startDate: _selectedDate.subtract(const Duration(days: 30)),
                            endDate: _selectedDate,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading data',
                                  style: TextStyle(color: Colors.red[300]),
                                ),
                              );
                            }
                            
                            final data = snapshot.data ?? [];
                            return CustomPaint(
                              painter: ScatterPlotPainter(correlationData: data),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BlurText(
                              text: 'Strong positive correlation',
                              duration: const Duration(milliseconds: 800),
                              type: AnimationType.word,
                              textStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ChimeBellText(
                              text:
                                  'When you take your medications\nregularly, your symptoms\ntypically improve within 2 days',
                              duration: const Duration(milliseconds: 50),
                              textStyle: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // NEW SECTION: Mood Trend Chart
                  BlurText(
                    text: 'Mood Trends Analysis',
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ChimeBellText(
                    text: 'Visualize how your mood has changed over time',
                    duration: const Duration(milliseconds: 50),
                    textStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: MoodTrendChart(
                      timeRange: _selectedDateOption,
                      selectedDate: _selectedDate,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // NEW SECTION: Correlation Analysis
                  BlurText(
                    text: 'Wellness Factor Analysis',
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ChimeBellText(
                    text:
                        'Discover which factors most strongly influence your mood',
                    duration: const Duration(milliseconds: 50),
                    textStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const SizedBox(
                    width: double.infinity,
                    child: CorrelationAnalysis(),
                  ),
                  const SizedBox(height: 30),

                  // NEW SECTION: Wellness Prediction
                  BlurText(
                    text: 'Mood Forecast',
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ChimeBellText(
                    text: 'AI-powered prediction of your mood trends',
                    duration: const Duration(milliseconds: 50),
                    textStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const SizedBox(
                    width: double.infinity,
                    child: WellnessPrediction(),
                  ),
                  const SizedBox(height: 30),

                  // NEW SECTION: Personalized Insights
                  BlurText(
                    text: 'Your Personalized Insights',
                    duration: const Duration(milliseconds: 800),
                    type: AnimationType.word,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ChimeBellText(
                    text:
                        'Data-driven recommendations tailored to your wellness patterns',
                    duration: const Duration(milliseconds: 50),
                    textStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: PersonalizedInsights(timeRange: _selectedDateOption),
                  ),
                  const SizedBox(height: 30),


                  const SizedBox(height: 30),

                  const SizedBox(height: 10),
                ]),
            ),
            ]),
          ),
        ),
      ),
      bottomNavigationBar:
          buildBottomNavigationBar(context: context, currentRoute: 'wellness'),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final now = DateTime.now();

    switch (_selectedDateOption) {
      case 'day':
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
          firstDate: DateTime(2020),
          lastDate: now,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          wellnessNotifier.setDate(pickedDate);

          "Selected date: $formattedSelectedDate".log();
        }
        break;

      case 'month':
        // Show month picker
        await _showMonthPicker(context);
        break;

      case 'year':
        // Show year picker
        await _showYearPicker(context);
        break;
    }
  }

  // Custom month picker
  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final date = DateTime(_selectedDate.year, month, 1);
                final isSelected = _selectedDate.month == month;
                final isFuture = date.year == now.year && month > now.month;

                return InkWell(
                  onTap: isFuture
                      ? null
                      : () {
                          wellnessNotifier.setDate(DateTime(
                            _selectedDate.year,
                            month,
                            1,
                          ));
                          Navigator.pop(context);
                          "Selected month: $formattedSelectedDate".log();
                        },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('MMM').format(DateTime(2022, month)),
                        style: TextStyle(
                          color: isFuture
                              ? Colors.grey[400]
                              : isSelected
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Custom year picker
  Future<void> _showYearPicker(BuildContext context) async {
    final now = DateTime.now();
    final startYear = 2020;
    final endYear = now.year;
    final years =
        List.generate(endYear - startYear + 1, (index) => startYear + index);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected = _selectedDate.year == year;

                return ListTile(
                  title: Text(year.toString()),
                  selected: isSelected,
                  selectedTileColor:
                      Theme.of(context).primaryColor.withAlpha(50),
                  textColor: isSelected ? Theme.of(context).primaryColor : null,
                  onTap: () {
                    wellnessNotifier.setDate(DateTime(
                      year,
                      _selectedDate.month,
                      1,
                    ));
                    Navigator.pop(context);
                    "Selected year: $formattedSelectedDate".log();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text.capitalize(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _moodIcon({required int index, int intensity = 500}) {
    bool isSelected = _selectedMood == index;

    // For day view, show the mood selection UI similar to journal screen
    if (_selectedDateOption == 'day') {
      return GestureDetector(
        onTap: () async {
          setState(() {
            _selectedMood = index;
          });

          // Save mood data using HiveService
          await _saveMoodData(index);

          // Force a rebuild to update the UI
          setState(() {});
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? Colors.pink[100] : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.pink.withAlpha(76),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: CustomPaint(
              painter: MoodPainter(index, isSelected),
              size: const Size(30, 20),
            ),
          ),
        ),
      );
    }
    // For month view, show the aggregated data
    else if (_selectedDateOption == 'month') {
      MoodTracker.populateSample();
      isSelected = true;
      final int moodCount = MoodTracker.getMoodCountByRange(
          DateTime(_selectedDate.year, _selectedDate.month, 1),
          DateTime(_selectedDate.year, _selectedDate.month, 30),
          index + 1);
      intensity = 50 + ((moodCount / MoodTracker.moodLog.length) * 800).toInt();
      intensity -= intensity % 100;
    }

    // For other views (year) or default case
    else {
      intensity -= intensity % 100;
    }

    // Return the default visualization for non-day views
    return GestureDetector(
      onTap: () {
        if (_selectedDateOption == 'day') {
          setState(() {
            _selectedMood = index;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[intensity] : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: CustomPaint(
            painter: MoodPainter(index, isSelected && intensity >= 500),
            size: const Size(30, 20),
          ),
        ),
      ),
    );
  }

  Widget _dayIndicator(String day, bool isComplete) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? Colors.green[100] : Colors.pink[100],
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _effectivenessBar(String medication, double score, Color color) {
    // Assuming score is on a scale of 0-10
    final fillPercentage = score / 10.0;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            medication,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              // Background bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Filled portion based on score
              FractionallySizedBox(
                widthFactor: fillPercentage,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Column buildSymptomsAndTriggers() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _symptomItem('Headache', 0.8),
            _symptomItem('Fatigue', 0.6),
            _symptomItem('Nausea', 0.3),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _triggerItem('Stress', 0.7),
            _triggerItem('Poor Sleep', 0.5),
            _triggerItem('Caffeine', 0.4),
          ],
        ),
      ],
    );
  }

  Widget _symptomItem(String name, double frequency) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.sick,
            color: Colors.red[400],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(frequency * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
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
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.warning_amber,
            color: Colors.orange[400],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(frequency * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Column buildMissedDosagePatterns() {
    final pillIntakeNotifier = ref.watch(pillIntakeProvider.notifier);
    final missedDays = pillIntakeNotifier.getMissedDoseDays();

    return Column(
      children: [
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
        const SizedBox(height: 15),
        BlurText(
          text: missedDays.isEmpty
              ? 'Great job! You haven\'t missed any doses recently.'
              : 'You tend to miss doses on ${missedDays.join(' and ')}',
          duration: const Duration(milliseconds: 800),
          type: AnimationType.word,
          textStyle: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _medicineAdherenceBar() {
    final medications = ref.watch(pillIntakeProvider);
    final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
    final journalLog = pillIntakeNotifier.journalLog;

    // Calculate date range based on selected date option
    final DateTime startDate = getStartDate(_selectedDateOption, _selectedDate);
    final DateTime endDate = _selectedDate;

   /* switch (_selectedDateOption) {
      case 'day':
        // For a day, just use the selected date
        startDate = _selectedDate;
        break;
      case 'month':
        // For a month, use the first day of the month to the selected date
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        break;
      case 'year':
        // For a year, use the first day of the year to the selected date
        startDate = DateTime(_selectedDate.year, 1, 1);
        break;
      default:
        // Default to last 30 days
        startDate = _selectedDate.subtract(const Duration(days: 30));
    }*/

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final treatment = medications[index].treatment;
        final medName = treatment.medicine.name;

        final double adherenceRate =
            journalLog.getAdherenceRate(treatment, startDate, endDate);

        // Convert to a 0-10 scale for the UI
        final double medRate = adherenceRate * 10;
        final medColor = medRate < 7 ? Colors.purple[100] : Colors.green[200];

        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _effectivenessBar(medName, medRate, medColor!));
      },
    );
  }

  Row _buildMedicationAdherenceCard() {
    String currentTimeFrame = _selectedDate.getNameOf(_selectedDateOption);
    currentTimeFrame = currentTimeFrame == 'today'
        ? 'today'
        : _selectedDateOption == 'day'
            ? 'on $currentTimeFrame'
            : 'in $currentTimeFrame';
    final String previousTimeFrame = currentTimeFrame == 'today'
        ? 'yesterday'
        : 'the previous $_selectedDateOption';

    // Calculate date range based on selected date option
    final DateTime startDate = getStartDate(_selectedDateOption, _selectedDate);
    final DateTime endDate = _selectedDate;
    final journalLog = ref.read(pillIntakeProvider.notifier).journalLog;
    final double currentAdherence = journalLog.getAdherenceRateAll(startDate, endDate);;
    final currentText =
        "You've taken ${currentAdherence * 100}% of your meds $currentTimeFrame";
    final progressText =
        "That's better than $previousTimeFrame (${(currentAdherence - 0.05) * 100}%)";
    return Row(
      children: [
        CircularPercentIndicator(
          radius: 35,
          lineWidth: 6,
          percent: currentAdherence,
          center: Text(
            '${currentAdherence * 100}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          progressColor: Colors.purple[100],
          backgroundColor: Colors.grey[200]!,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentText,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                progressText,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: Colors.grey.withOpacity(0.1),
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

  // Save the mood data to HiveService
  Future<void> _saveMoodData(int mood) async {
    try {
      // Use the selected date
      final date = _selectedDate;

      // Use the HiveService method to save mood data
      await HiveService.saveMoodForDate(date, mood, '');

      // Force UI update
      setState(() {
        _selectedMood = mood;
      });
    } catch (e) {
      "Error saving mood data: $e".log();
    }
  }
}
