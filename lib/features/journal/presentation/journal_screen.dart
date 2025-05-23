import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/journal/presentation/daily_mood_prompt.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';

import '../../../core/theme/icons.dart';
import '../../../core/util/dateFormatConverters.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../data/journal_log.dart';
import 'journal_notifier.dart';


class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => JournalScreenState();
}

class JournalScreenState extends ConsumerState<JournalScreen> {
  late final ScrollController _dateScrollController;
  late final PageController _pageController;
  late DateTime selectedDate;
  late List<IntakeLog> medList = [];

  @override
  void initState() {
    super.initState();
    _dateScrollController = ScrollController();
    _pageController = PageController(initialPage: 1000);

    // Check for daily mood prompt with a delay
    Future.delayed(Duration(seconds: 3), () {
      _checkDailyMood();
    });

    // Initialize the date selector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double targetScroll = MediaQuery.of(context).size.width / 5 * 2;

      _dateScrollController.animateTo(
        targetScroll,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    final selectedDateNotifier = ref.read(selectedDateProvider.notifier);
    selectedDateNotifier.setDate(DateTime.now().add(Duration(days: page - 1000)), ref);
    setState(() {

      // Scroll the date selector if necessary
      WidgetsBinding.instance.addPostFrameCallback((_) {
        double itemWidth = MediaQuery.of(context).size.width / 5;
        double targetScroll = (page - 1000) * itemWidth;

        _dateScrollController.animateTo(
          targetScroll,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    });
  }


  // Check if it's the first launch of the day and show mood prompt
  void _checkDailyMood() async {
    try {
      // Check if user has already logged mood for today
      final today = DateTime.now();
      final hasMoodToday = await HiveService.hasMoodForDate(today);

      // Only show the mood prompt if user hasn't logged mood today
      if (!hasMoodToday) {
        final isFirstLaunch = await HiveService.isFirstLaunchOfDay();
        if (isFirstLaunch) {
          // Wait a moment for the UI to settle
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          // Show the daily mood prompt
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return DailyMoodPrompt(
                onComplete: () {
                  Navigator.of(context).pop();
                  HiveService.setMoodEntryForToday();
                  setState(() {});
                },
              );
            },
          );
        }
      }
    } catch (e) {
      // Handle any errors
      devPrint('Error checking daily mood: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    selectedDate = ref.watch(selectedDateProvider);
    //medList = JournalLog().getMedicationsForTheDay(selectedDate);
    medList = ref.watch(pillIntakeProvider);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Journal',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () {
              context.go('/profile');
            },
            child: Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink[50],
              ),
              child: appVectorImage(fileName: 'profile'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
            color: Colors.pink[100],
            backgroundColor: Colors.white,
            onRefresh: _refreshJournal,
            child: Column(
                children: [
                  _buildDateSelector(),
                  Expanded(
                    child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          //final date = DateTime.now().add(Duration(days: index - 1000));
                          return ListView(
                            children: [
                              _buildTodayHeading(),
                              _buildMorningSection(),
                              _buildEveningSection(),
                            ],
                          );
                        },
                      ),
                  ),
                ],
              )
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: buildBottomNavigationBar(context: context, currentRoute: 'journal'),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index - 2));
          bool isSelected = date.day == selectedDate.day &&
                            date.month == selectedDate.month &&
                            date.year == selectedDate.year;
          bool isToday = date.day == DateTime.now().day &&
                         date.month == DateTime.now().month &&
                         date.year == DateTime.now().year;
          return SizedBox(
            width: MediaQuery.of(context).size.width / 5,
            child: GestureDetector(
              onTap: () {
                if (isToday) {
                  _showDatePicker(context);
                } else {
                  int difference = date.difference(DateTime.now()).inDays;
                  _pageController.animateToPage(
                    1000 + difference,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.grey[800] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      getWeekdayAbbreviation(date.weekday),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.pink[100],
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.pink[100],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          // Update the selected date
                          int difference = selectedDate.difference(DateTime.now()).inDays;
                          _pageController.animateToPage(
                            1000 + difference,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime(2101),
                  onDateTimeChanged: (DateTime newDate) {
                    final selectedDateNotifier = ref.read(selectedDateProvider.notifier);
                    selectedDateNotifier.setDate(newDate, ref);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayHeading() {
    final date = selectedDate;
    String headingText;
    if (date.day == DateTime.now().day) {
      headingText = 'Today';
    } else if (date.day == DateTime.now().add(Duration(days: 1)).day) {
      headingText = 'Tomorrow';
    } else if (date.day == DateTime.now().subtract(Duration(days: 1)).day) {
      headingText = 'Yesterday';
    } else {
      headingText = '${getWeekdayName(date.weekday)}, ${date.day}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            headingText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildMoodCard(date),
      ],
    );
  }

  // Build the mood card for the selected date
  Widget _buildMoodCard(DateTime date) {
    // Check if the date is in the future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isAfter(today)) {
      // Don't show mood card for future dates
      return const SizedBox.shrink();
    }

    // Use FutureBuilder to handle async data loading
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getMoodData(date),
      builder: (context, snapshot) {
        // Default values
        bool hasMood = false;
        Map<String, dynamic>? moodData;

        // Check if we have data
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          hasMood = true;
          moodData = snapshot.data;
        }

        // Determine card background color based on mood
        Color cardColor = Colors.grey[100]!;
        if (hasMood && moodData != null) {
          final mood = moodData['mood'] as int;
          // Gradient from light pink to light yellow based on mood (sad to happy)
          if (mood <= 1) {
            cardColor = Colors.blue[50]!; // Sad mood
          } else if (mood == 2) {
            cardColor = Colors.grey[100]!; // Neutral mood
          } else {
            cardColor = Colors.pink[50]!; // Happy mood
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: cardColor,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (hasMood && moodData != null) {
                  // Show full mood description
                  _showMoodDetails(date, moodData);
                } else {
                  // Show mood input dialog
                  _showAddMoodDialog(date);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlurText(
                            text: hasMood && (moodData?['mood'] != null)
                            ? 'I felt ${getMoodLabel(moodData?['mood']).toLowerCase()}'
                            : 'How did you feel?',
                            duration: const Duration(milliseconds: 500),
                            type: AnimationType.word,
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (hasMood && moodData != null) SizedBox(height: 8),
                          if (hasMood && moodData != null)
                            ChimeBellText(
                              text: (moodData['description'] as String),
                              duration: Duration(milliseconds:
                              moodData['description'].toString().isEmpty
                                ? 500 // Default duration if description is empty
                                : (500 / (moodData['description'].toString().length)).toInt()
                              ),
                              type: AnimationType.letter,
                              textStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              /*maxLines: 1,
                              overflow: TextOverflow.ellipsis,*/
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: hasMood && moodData != null ? Colors.white : Colors.grey[200],
                        shape: BoxShape.circle,
                        boxShadow: hasMood && moodData != null ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 2,
                            spreadRadius: 1,
                          )
                        ] : null,
                      ),
                      child: hasMood && moodData != null
                        ? Center(
                            child: Text(
                              getMoodEmoji(moodData['mood'] as int),
                              style: TextStyle(fontSize: 24),
                            ),
                          )
                        : Icon(
                            Icons.add,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to get mood data asynchronously
  Future<Map<String, dynamic>?> _getMoodData(DateTime date) async {
    try {
      final hasMood = await HiveService.hasMoodForDate(date);
      if (hasMood) {
        return await HiveService.getMoodForDate(date);
      }
      return null;
    } catch (e) {
      devPrint('Error loading mood data: $e');
      return null;
    }
  }

  // Show detailed mood information in a bottom sheet
  void _showMoodDetails(DateTime date, Map<String, dynamic> moodData) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final mood = moodData['mood'] as int;
        final description = moodData['description'] as String;

        // Parse timestamp - handle both string and int formats
        DateTime timestamp;
        if (moodData['timestamp'] is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(moodData['timestamp'] as int);
        } else {
          timestamp = DateTime.parse(moodData['timestamp'] as String);
        }

        final timeString = DateFormat('h:mm a').format(timestamp);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 4,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    getMoodEmoji(mood),
                    style: TextStyle(fontSize: 60),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                getMoodLabel(mood),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Recorded at $timeString',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Close'),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditMoodDialog(date, moodData);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[100],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Show dialog to add mood for a date
  void _showAddMoodDialog(DateTime date) {
    // Check if the date is in the future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isAfter(today)) {
      // Show error message for future dates
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add mood entries for future dates'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DailyMoodPrompt(
          date: date, // Pass the selected date
          onComplete: () {
            Navigator.of(context).pop();
            setState(() {
              // Refresh the UI to show the new mood
            });
          },
        );
      },
    );
  }

  // Show dialog to edit mood for a date
  void _showEditMoodDialog(DateTime date, Map<String, dynamic> moodData) {
    final int initialMood = moodData['mood'] as int;
    final String initialDescription = moodData['description'] as String;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditMoodDialog(
          initialMood: initialMood,
          initialDescription: initialDescription,
          date: date,
          onComplete: () {
            Navigator.of(context).pop();
            setState(() {
              // Refresh the UI to show the updated mood
            });
          },
        );
      },
    );
  }


  Widget _buildMorningSection() {
    final date = selectedDate;
    final List<IntakeLog> medications = medList.forMorning();

    return medications.isEmpty ? SizedBox() : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Morning - ${date.day.ordinal()} ${getMonthName(date.month)}', Icons.wb_sunny_outlined),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            return _buildMedicationItem(
                medications[index]
            );
          },
        ),
      ],
    );
  }

  Widget _buildEveningSection() {
    final date = selectedDate;
    final List<IntakeLog> medications = medList.forEvening();

    return medications.isEmpty ? SizedBox() : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Evening - ${date.day.ordinal()} ${getMonthName(date.month)}', Icons.nights_stay_outlined),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            return _buildMedicationItem(
                medications[index]
            );
          },
        ),
      ],
    );
  }

  Padding _buildSectionHeader(String title, IconData icon) {
    // Get emoji based on icon
    String emoji = '';
    if (icon == Icons.wb_sunny_outlined) {
      emoji = '☀️'; // Sun emoji for morning
    } else if (icon == Icons.nights_stay_outlined) {
      emoji = '🌙'; // Moon emoji for evening
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  InkWell _buildMedicationItem(IntakeLog medicineLog) {
    final bool isTaken = medicineLog.isTaken;
    final medication = medicineLog.treatment;
    final String name = medication.medicine.name;
    String type = medication.medicine.type.toLowerCase();
    final String dosage = '${medication.medicine.specs.dosage} ${medication.medicine.specs.unit}';
    final String time = medication.timeOfDay();
    final String color = medication.medicine.color;

    if (type.endsWith('s')) {
      type = type.substring(0, type.length - 1);
    }

    return InkWell(
      onTap: () => _showMedicationDetails(medicineLog),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: futureBuildSvg(type, color)
                ),
                if (isTaken)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle, color: Colors.green, size: 14),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dosage,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Text(
              time,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            /*Icon(Icons.chevron_right, color: Colors.grey),*/
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showAddPopup(context),
      backgroundColor: Colors.pink[100],
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white), // This makes the button circular
    );
  }

  void _showAddPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'What do you want to add?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 20),
                _buildOptionButton(
                  icon: appImage('medicine', size: 30),
                  text: 'New treatment',
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    context.push('/new_treatment'); // Navigate to new treatment screen
                  },
                ),
                SizedBox(height: 10),
                _buildOptionButton(
                  icon: appImage('one-time-medicine', size: 30),
                  text: 'One-time take',
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    context.push('/new_treatment'); // Navigate to new treatment screen
                  },
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: 15),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicationDetails(IntakeLog medicineLog) {
    final medication = medicineLog.treatment;
    final String name = medication.medicine.name;
    final String dosage = '${medication.medicine.specs.dosage} ${medication.medicine.specs.unit}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$name • $dosage',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => context.push('/edit_treatment', extra: medication),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildInfoItem('${medication.medicine.color.capitalize()} ${medication.medicine.type}'),
              _buildInfoItem(medication.treatmentPlan.mealOption.isNotEmpty 
                ? medication.treatmentPlan.mealOption 
                : 'Take as directed'),
              _buildInfoItem(medication.treatmentPlan.instructions.isNotEmpty 
                ? medication.treatmentPlan.instructions 
                : 'Try to take it at the same time each day'),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle skip action
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red, backgroundColor: Colors.grey[200],
                      ),
                      child: const Text('Skip for today'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        // Get the pill intake notifier and use the async version of pillTaken
                        final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
                        pillIntakeNotifier.pillTaken(medicineLog, selectedDate).then((_) {
                          _showPillTakenDialog(context);
                          setState(() {
                            // Log for debugging
                            devPrint('Pill taken: ${medicineLog.isTaken}');
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.pink[100],
                      ),
                      child: const Text('Take pill'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Handle postpone action
                    Navigator.pop(context);
                  },
                  child: Text('Postpone', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPillTakenDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        String? pillLogError;
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                pillLogError ?? 'Pill taken!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.green, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _refreshJournal() async {
    try {
      // Force reload from Hive storage
      final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
      await pillIntakeNotifier.forceReloadMedicationData(selectedDate);

      // Also update the date
      final selectedDateNotifier = ref.read(selectedDateProvider.notifier);
      await selectedDateNotifier.setDate(selectedDate, ref);

      "Journal refreshed with force reload".log();
    } catch (e) {
      "Error refreshing journal: $e".log();
    }
  }
}

// Dialog to edit mood entries
class EditMoodDialog extends StatefulWidget {
  final int initialMood;
  final String initialDescription;
  final DateTime date;
  final VoidCallback onComplete;

  const EditMoodDialog({
    super.key,
    required this.initialMood,
    required this.initialDescription,
    required this.date,
    required this.onComplete,
  });

  @override
  State<EditMoodDialog> createState() => EditMoodDialogState();
}

class EditMoodDialogState extends State<EditMoodDialog> {
  @override
  Widget build(BuildContext context) {
    // Debug log to verify the edit dialog is being called with correct values
    devPrint('EditMoodDialog: Editing mood with initialMood=${widget.initialMood}, initialDescription="${widget.initialDescription}"');

    // Instead of using a custom edit dialog, we reuse DailyMoodPrompt
    // but pass in the initial values and date
    return DailyMoodPrompt(
      onComplete: () {
        devPrint('EditMoodDialog: Edit completed successfully');
        widget.onComplete();
      },
      date: widget.date,
      initialMood: widget.initialMood,
      initialDescription: widget.initialDescription,
      isEditing: true, // Flag to indicate this is an edit operation
    );
  }
}

String getMoodEmoji(int mood) {
  switch (mood) {
    case 0:
      return '😢'; // Very Sad
    case 1:
      return '😔'; // Sad
    case 2:
      return '😐'; // Neutral
    case 3:
      return '😊'; // Happy
    case 4:
      return '😁'; // Very Happy
    default:
      return '😐'; // Default to neutral
  }
}
String getMoodLabel(int mood) {
  switch (mood) {
    case 0:
      return 'Very Sad';
    case 1:
      return 'Sad';
    case 2:
      return 'Neutral';
    case 3:
      return 'Happy';
    case 4:
      return 'Very Happy';
    default:
      return 'Unknown';
  }
}
