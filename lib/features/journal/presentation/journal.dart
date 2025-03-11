import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/core/util/helpers.dart';
import 'dart:async';

import '../../../core/theme/icons.dart';
import '../../../core/util/dateFormatConverters.dart';
import '../../../core/widgets/appbar.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/services/hive_service.dart';
import '../../../features/splash/daily_mood_prompt.dart';
import '../data/journal_log.dart';
import 'journal_notifier.dart';

//todo: Implement proper journal entry model with cloud synchronization

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => JournalScreenState();
}

class JournalScreenState extends ConsumerState<JournalScreen> {
  final PageController _pageController = PageController(initialPage: 1000);
  final ScrollController _dateScrollController = ScrollController();
  late DateTime selectedDate;
  late List<IntakeLog> medList = [];

  @override
  void initState() {
    super.initState();
    //todo: Load saved journal entries from local storage or cloud
    
    // Check for daily mood prompt with a gentle delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _checkDailyMood();
      }
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

  //todo: Implement journal entry saving functionality
  
  // Check if it's the first launch of the day and show mood prompt
  void _checkDailyMood() {
    if (HiveService.isFirstLaunchOfDay()) {
      // Show the daily mood prompt with a gentle animation
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (BuildContext context) {
          return DailyMoodPrompt(
            onComplete: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
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
      appBar: buildAppBar('Journal'),
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
    //todo: Improve date selector with better UI and month view option
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        headingText,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Column _buildMorningSection() {
    final date = selectedDate;
    final List<IntakeLog> medications = medList.forMorning();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Morning - ${date.day}/${date.month}', Icons.wb_sunny_outlined),
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

  Column _buildEveningSection() {
    final date = selectedDate;
    final List<IntakeLog> medications = medList.forEvening();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Evening - ${date.day}/${date.month}', Icons.nights_stay_outlined),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
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
    //todo: Make sure that on pill taken, the takenMedications list is updated
    final bool isTaken = medicineLog.isTaken;
    final medication = medicineLog.treatment;
    final String name = medication.medicine.name;
    final String dosage = '${medication.medicine.specs.dosage} ${medication.medicine.specs.unit}';
    final String time = medication.timeOfDay();

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
                  child: appImage('medicine'),
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
            Icon(Icons.chevron_right, color: Colors.grey),
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
                    // Handle one-time take
                    Navigator.of(context).pop();
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
                    onPressed: () {
                      // Handle edit action
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildInfoItem('Blue pill'),
              _buildInfoItem('Take at least 30 minutes before breakfast.'),
              _buildInfoItem('Try to take it at the same time each day.'),
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
                        _showPillTakenDialog(context);
                        setState(() {

                          devPrint(medicineLog.isTaken);
                          medicineLog.isTaken = true;
                          devPrint(medicineLog.isTaken);
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
                  child: Text('Postpone', style: TextStyle(color: Colors.grey)),
                  onPressed: () {
                    // Handle postpone action
                    Navigator.pop(context);
                  },
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
    // Simulate a data fetch operation
    await Future.delayed(Duration(seconds: 1));
    final selectedDateNotifier = ref.read(selectedDateProvider.notifier);
    selectedDateNotifier.setDate(DateTime.now(), ref);
  }
}
