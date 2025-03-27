import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/wellness/domain/wellness_tracker.dart';
import 'package:pillow/features/wellness/presentation/components/correlation_analysis.dart';
import 'package:pillow/features/wellness/presentation/components/mood_trend_chart.dart';
import 'package:pillow/features/wellness/presentation/components/personalized_insights.dart';
import 'package:pillow/features/wellness/presentation/components/wellness_prediction.dart';
import 'package:pillow/features/wellness/presentation/wellness_notifier.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/bottom_navigation.dart';
import '../../journal/presentation/journal_notifier.dart';
import 'components/mood_painter.dart';
import 'components/scatter_plot_painter.dart';

//todo: Implement wellness data persistence and analytics

class WellnessTrackerScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  
  const WellnessTrackerScreen({
    super.key,
    this.initialDate,
  });

  @override
  ConsumerState<WellnessTrackerScreen> createState() => WellnessTrackerScreenState();
}

class WellnessTrackerScreenState extends ConsumerState<WellnessTrackerScreen> {
  int _selectedMood = MoodTracker.getMood(DateTime.now()) - 1;
  String _selectedDateOption = 'month';
  late DateTime _selectedDate;
  late WellnessScreenNotifier wellnessNotifier;
  
  @override
  void initState() {
    super.initState();
    //_selectedDate = widget.initialDate ?? DateTime.now();
    wellnessNotifier = ref.read(wellnessScreenProvider.notifier);
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
        wellnessNotifier.setDate(_selectedDate.subtract(const Duration(days: 1)));
        break;
      case 'month':
        wellnessNotifier.setDate(
          DateTime(
          _selectedDate.year,
          _selectedDate.month - 1,
          _selectedDate.day,
        ));
        break;
      case 'year':
      wellnessNotifier.setDate(
          DateTime(
            _selectedDate.year - 1,
            _selectedDate.month,
            _selectedDate.day,
          )
      );
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

  @override
  Widget build(BuildContext context) {
    _selectedDate = ref.watch(wellnessScreenProvider);
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Center(
                  child: Text(
                    "${_selectedDate.getNameOf(_selectedDateOption)}'s Wellness Report",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Track your journey and nurture your\nwhole self - mind and body together.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Mood tracker
                //todo: Implement mood tracking history and trends analysis
                BlurText(
                  key: ValueKey('$_selectedDateOption: $_selectedDate'),
                  text:
                  wellnessNotifier.checkInMessage(_selectedDateOption),
                  duration: const Duration(seconds: 1),
                  type: AnimationType.word,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  )
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
                    const Text(
                      'Want to share more details?',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),

                const SizedBox(height: 30),

                // Medication adherence
                //todo: Connect with actual medication data from pillbox
                const Text(
                  'Medication adherence',
                  style: TextStyle(
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
                const Text(
                  'Missed dose patterns',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),

                buildMissedDosagePatterns(),

                const SizedBox(height: 30),

                // Active symptoms and triggers
                buildSymptomsAndTriggers(),

                const SizedBox(height: 30),

                // Medication impact
                const Text(
                  'Medication impact',
                  style: TextStyle(
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
                      child: CustomPaint(
                        painter: ScatterPlotPainter(),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Strong positive correlation',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'When you take your medications\nregularly, your symptoms\ntypically improve within 2 days',
                            style: TextStyle(
                              color: Colors.grey[600],
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
                const Text(
                  'Mood Trends Analysis',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visualize how your mood has changed over time',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
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
                const Text(
                  'Wellness Factor Analysis',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover which factors most strongly influence your mood',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
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
                const Text(
                  'Mood Forecast',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-powered prediction of your mood trends',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
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
                const Text(
                  'Your Personalized Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data-driven recommendations tailored to your wellness patterns',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: PersonalizedInsights(timeRange: _selectedDateOption),
                ),
                const SizedBox(height: 30),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(context: context, currentRoute: 'wellness'),
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
                  onTap: isFuture ? null : () {
                    wellnessNotifier.setDate(
                      DateTime(
                      _selectedDate.year,
                      month,
                      1,
                      )
                    );
                    Navigator.pop(context);
                    "Selected month: $formattedSelectedDate".log();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                      ),
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
    final years = List.generate(endYear - startYear + 1, (index) => startYear + index);
    
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
                  selectedTileColor: Theme.of(context).primaryColor.withAlpha(50),
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
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
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
    if(_selectedDateOption == 'month') {
      MoodTracker.populateSample();
      isSelected = true;
      final int moodCount = MoodTracker.getMoodCountByRange(
      DateTime(DateTime.now().year, DateTime.now().month, 1),
      DateTime(DateTime.now().year, DateTime.now().month, 30),
      index + 1
      );
      intensity =  50 + ((moodCount / MoodTracker.moodLog.length) * 800).toInt();
    }
    intensity -= intensity % 100;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = index;
        });
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
            color: Colors.grey[600],
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

  Widget _symptomItem(int count, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Row _buildMedicationAdherenceCard() {
    String currentTimeFrame = _selectedDate.getNameOf(_selectedDateOption);
    currentTimeFrame = currentTimeFrame == 'Today' ? 'today' : _selectedDateOption == 'day' ? 'on $currentTimeFrame' : 'in $currentTimeFrame';
    final String previousTimeFrame = currentTimeFrame == 'today' ? 'yesterday' : 'the previous $_selectedDateOption';
    const double currentAdherence = 0.85;
    final currentText = "You've taken ${currentAdherence * 100}% of your meds $currentTimeFrame";
    final progressText = "That's better than $previousTimeFrame (${(currentAdherence - 0.05) * 100}%)";
    return Row(
      children: [
        CircularPercentIndicator(
          radius: 35,
          lineWidth: 6,
          percent: currentAdherence,
          center: const Text(
            '${currentAdherence * 100}%',
            style: TextStyle(
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
              ChimeBellText(
                key: ValueKey('$currentTimeFrame : $currentAdherence'),
                text: currentText,
                duration: Duration(milliseconds: 500),
                type: AnimationType.word,
                overlapFactor: 0.5,
                textAlignment: TextAlignment.start,
                textStyle: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                progressText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _triggerItem(String title, Color color) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Row buildSymptomsAndTriggers() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active symptoms',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 15),
              _symptomItem(12, 'Headache', '12 occurrences this month', Colors.purple),
              const SizedBox(height: 8),
              _symptomItem(5, 'Fatigue', '5 occurrences this month', Colors.purple),
              const SizedBox(height: 8),
              _symptomItem(2, 'Dizziness', '2 occurrences this month', Colors.purple),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top triggers',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 15),
              _triggerItem('Stress', Colors.pink[100]!),
              const SizedBox(height: 8),
              _triggerItem('Poor sleep', Colors.orange[100]!),
              const SizedBox(height: 8),
              _triggerItem('Screen time', Colors.yellow[200]!),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _medicineAdherenceBar(){
    final medications = ref.watch(pillIntakeProvider);
    //final medications = JournalLog().getMedicationsForTheDay(_selectedDate);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medName = medications[index].treatment.medicine.name;
        final double medRate = medications[index].isTaken ? 10 : 9.5 - (index * 1.8);
        final medColor = medRate < 7 ? Colors.purple[100] : Colors.green[200];
        return
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _effectivenessBar(medName, medRate, medColor!)
        );
      },
    );
  }
  
  Column buildMissedDosagePatterns(){
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _dayIndicator('Mon', true),
            _dayIndicator('Tue', true),
            _dayIndicator('Wed', false),
            _dayIndicator('Thu', true),
            _dayIndicator('Fri', true),
            _dayIndicator('Sat', false),
            _dayIndicator('Sun', true),
          ],
        ),
        const SizedBox(height: 15),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'You tend to miss evening doses on Wednesdays and Saturdays',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}