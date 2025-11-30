import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/presentation/daily_mood_prompt.dart';
import 'package:pinkrain/features/treatment/domain/treatment_manager.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/date_format_converters.dart';
import '../../../core/widgets/index.dart';
import '../data/journal_log.dart';
import 'journal_notifier.dart';
import 'journal_medication_notifier.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => JournalScreenState();
}

class JournalScreenState extends ConsumerState<JournalScreen> with WidgetsBindingObserver {
  late final PageController _dateScrollController;
  late final PageController _pageController;
  late DateTime selectedDate;
  late List<IntakeLog> medList = [];
  int _moodRefreshKey = 0; // Key to force mood widget refresh

  @override
  void initState() {
    super.initState();
    // Initialize with offset of 1000 to allow scrolling to past weeks
    _dateScrollController = PageController(initialPage: 1000);
    _pageController = PageController(initialPage: 1000);

    // Add lifecycle observer to detect when app comes back to foreground
    WidgetsBinding.instance.addObserver(this);

    // Check for daily mood prompt with a delay
    Future.delayed(Duration(seconds: 3), () {
      _checkDailyMood();
    });

    // Initialize the date selector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // CRITICAL FIX: Initialize journal data for today's date
      _onPageChanged(1000);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh journal data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshJournalData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  // Helper method to refresh journal data
  Future<void> _refreshJournalData() async {
    if (!mounted) return;
    try {
      final selectedDate = ref.read(selectedDateProvider);
      await ref.read(pillIntakeProvider.notifier).forceReloadMedicationData(selectedDate);
      devPrint('📋 Journal data refreshed for ${selectedDate.toString().split(' ')[0]}');
      
      // CRITICAL FIX: Reschedule notifications after refresh (only for today)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (selectedDate.year == today.year && 
          selectedDate.month == today.month && 
          selectedDate.day == today.day) {
        devPrint('🔄 Rescheduling notifications after journal refresh');
        await ref.read(journalMedicationNotifierProvider.notifier).checkUntakenMedications();
      }
    } catch (e) {
      devPrint('❌ Error refreshing journal data: $e');
    }
  }

  void _onPageChanged(int page) {
    final today = normalizeDate(DateTime.now());
    final newDate = today.add(Duration(days: page - 1000));

    final selectedDateNotifier = ref.read(selectedDateProvider.notifier);
    selectedDateNotifier.setDate(newDate, ref);

    final weekIndex = getWeekIndex(newDate);
    // Offset by 1000 to allow scrolling backwards (negative weeks)
    _dateScrollController.jumpToPage(weekIndex + 1000);
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
          showModalBottomSheet(
            context: context,
            isDismissible: true,
            enableDrag: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return DailyMoodPrompt(
                onComplete: () {
                  Navigator.of(context).pop();
                  HiveService.setMoodEntryForToday();
                  setState(() {
                    _moodRefreshKey++;
                  });
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
    return Scaffold(
      backgroundColor: AppTokens.bgPrimary,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          backgroundColor: AppTokens.bgPrimary,
          automaticallyImplyLeading: false,
        ),
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
                    return MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: medList.isEmpty
                          ? Column(
                              children: [
                                _buildTodayHeading(),
                                Expanded(
                                  child: _buildEmptyState(),
                                ),
                              ],
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  padding: EdgeInsets.only(bottom: 100),
                                  physics: const ClampingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Column(
                                      children: [
                                        _buildTodayHeading(),
                                        _buildMorningSection(),
                                        _buildNoonSection(),
                                        _buildAfternoonSection(),
                                        _buildEveningSection(),
                                        _buildNightSection(),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          )),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar:
          buildBottomNavigationBar(context: context, currentRoute: 'journal'),
    );
  }

  // Build Empty State for no treatments
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            appVectorImage(
              fileName: 'water',
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'No treatments for today!',
              style: AppTokens.textStyleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              "Don't forget to drink some water 💧",
              style: AppTokens.textStyleMedium.copyWith(
                color: AppTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  DateTime normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  int getWeekIndex(DateTime date) {
    final mondayToday = normalizeDate(DateTime.now())
        .subtract(Duration(days: DateTime.now().weekday - 1));
    final mondayTarget =
        normalizeDate(date).subtract(Duration(days: date.weekday - 1));
    return mondayTarget.difference(mondayToday).inDays ~/ 7;
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      child: PageView.builder(
        controller: _dateScrollController,
        itemBuilder: (context, pageIndex) {
          // Convert page index (offset by 1000) back to actual week index
          final weekIndex = pageIndex - 1000;
          
          // Get Monday of the current week, then shift by weekIndex
          DateTime today = DateTime.now();
          int daysToSubtract =
              today.weekday - DateTime.monday; // weekday: 1 (Mon) to 7 (Sun)
          DateTime monday = DateTime(today.year, today.month, today.day)
              .subtract(Duration(days: daysToSubtract));
          DateTime startOfWeek = monday.add(Duration(days: weekIndex * 7));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (dayOffset) {
              final date = startOfWeek.add(Duration(days: dayOffset));
              final isSelected = selectedDate.day == date.day &&
                  selectedDate.month == date.month &&
                  selectedDate.year == date.year;
              final isToday = date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year;

              return GestureDetector(
                onTap: () {
                  int difference = normalizeDate(date)
                      .difference(normalizeDate(DateTime.now()))
                      .inDays;

                  final clickedWeekIndex = getWeekIndex(date);
                  _dateScrollController.jumpToPage(clickedWeekIndex + 1000);

                  _pageController.animateToPage(
                    1000 + difference,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 45,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.grey[800] : AppTokens.bgMuted,
                    borderRadius: BorderRadius.circular(18),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: Colors.grey[600] ?? Colors.grey.shade600,
                            width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getWeekdayAbbreviation(date.weekday),
                        style: TextStyle(
                          color: isSelected
                              ? AppTokens.textInvert
                              : AppTokens.textSecondary,
                          fontSize: 14,
                          fontWeight: AppTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? AppTokens.textInvert
                              : AppTokens.textPrimary,
                          fontSize: 18,
                          fontWeight: AppTokens.fontWeightW600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTodayHeading() {
    final date = selectedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateNormalized = DateTime(date.year, date.month, date.day);
    final isToday = selectedDateNormalized == today;
    
    String headingText;
    if (date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year) {
      headingText = 'Today, ${getMonthName(date.month)} ${date.day}';
    } else if (date.day == DateTime.now().add(Duration(days: 1)).day &&
               date.month == DateTime.now().month &&
               date.year == DateTime.now().year) {
      headingText = 'Tomorrow, ${getMonthName(date.month)} ${date.day}';
    } else if (date.day == DateTime.now().subtract(Duration(days: 1)).day &&
               date.month == DateTime.now().month &&
               date.year == DateTime.now().year) {
      headingText = 'Yesterday, ${getMonthName(date.month)} ${date.day}';
    } else {
      headingText = '${getWeekdayName(date.weekday)}, ${getMonthName(date.month)} ${date.day}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  headingText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: AppTokens.fontWeightBold,
                  ),
                ),
              ),
              if (!isToday)
                Material(
                  color: AppTokens.buttonPrimaryBg.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      // Navigate back to today
                      final difference = normalizeDate(DateTime.now())
                          .difference(normalizeDate(DateTime.now()))
                          .inDays;
                      
                      _pageController.animateToPage(
                        1000 + difference,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: AppTokens.fontWeightBold,
                          color: const Color.fromARGB(255, 248, 159, 248),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
      key: ValueKey('mood_${date.toIso8601String()}_$_moodRefreshKey'), // Force rebuild when key changes
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
        Color cardColor = Colors.grey[100] ?? Colors.grey.shade100;
        if (hasMood && moodData != null) {
          final mood = moodData['mood'] as int;
          // Gradient from light pink to light yellow based on mood (sad to happy)
          if (mood <= 1) {
            cardColor = Colors.blue[50] ?? Colors.blue.shade50; // Sad mood
          } else if (mood == 2) {
            cardColor =
                Colors.grey[100] ?? Colors.grey.shade100; // Neutral mood
          } else {
            cardColor = AppTokens.buttonPrimaryBg; // Happy mood
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
                  // Show board with all mood entries
                  _showMoodDetails(date, moodData);
                } else {
                  // Allow adding mood for today and past dates
                  _showAddMoodDialog(date);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Builder(
                  builder: (context) {
                    // Check if date is today
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final selectedDate = DateTime(date.year, date.month, date.day);
                    final isToday = selectedDate == today;
                    
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlurText(
                                text: (hasMood && moodData != null)
                                    ? 'Your mood notes'
                                    : isToday
                                        ? 'How do you feel?'
                                        : 'How were you feeling?',
                                duration: const Duration(milliseconds: 500),
                                type: AnimationType.word,
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: AppTokens.fontWeightBold,
                                  color: AppTokens.textPrimary,
                                ),
                              ),
                              if (hasMood && moodData != null) ...[
                                const SizedBox(height: 8),
                                FutureBuilder<List<Map<String, dynamic>>?>(
                                  future: HiveService.getMoodEntriesForDate(date),
                                  builder: (context, entriesSnapshot) {
                                    final entries = entriesSnapshot.data ?? const [];
                                    final notesCount = entries.isNotEmpty ? entries.length : 1;
                                    final label = notesCount == 1 ? 'note' : 'notes';
                                    final text = isToday
                                        ? 'Tap to see $notesCount $label'
                                        : '$notesCount $label';
                                    return Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTokens.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: hasMood && moodData != null
                              ? SvgPicture.asset(
                                  'assets/icons/${_getMoodIconName(moodData['mood'] as int)}.svg',
                                  width: 30,
                                  height: 30,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
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
        // Return the latest mood entry; count is computed where displayed
        return await HiveService.getMoodForDate(date);
      }
      return null;
    } catch (e) {
      devPrint('Error loading mood data: $e');
      return null;
    }
  }

  // Show detailed mood information in a bottom sheet
  void _showMoodDetails(DateTime date, Map<String, dynamic> moodData) async {
    // Load all mood entries for this date
    final moodEntries = await HiveService.getMoodEntriesForDate(date) ?? [moodData];
    
    // Check if date is today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    final isToday = selectedDate == today;
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {

        return Container(
          decoration: const BoxDecoration(
            color: AppTokens.bgPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Mood Notes',
                        style: AppTokens.textStyleXLarge,
                      ),
                      Text(
                        DateFormat('MMM d').format(date),
                        style: AppTokens.textStyleMedium.copyWith(
                          color: AppTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Notes Board
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.start,
                      children: moodEntries.map((entry) {
                        final mood = entry['mood'] as int;
                        final description = entry['description'] as String;
                        final rawTimestamp = entry['timestamp'];
                        
                        // Convert to DateTime based on type (int or String)
                        DateTime timestamp;
                        String timestampString;
                        if (rawTimestamp is int) {
                          timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
                          timestampString = rawTimestamp.toString(); // Preserve original int as string
                        } else if (rawTimestamp is String) {
                          timestamp = DateTime.parse(rawTimestamp);
                          timestampString = rawTimestamp; // Preserve original string
                        } else {
                          // Fallback if type is unexpected
                          timestamp = DateTime.now();
                          timestampString = timestamp.toIso8601String();
                        }
                        
                        final timeString = DateFormat('h:mm a').format(timestamp);
                        
                        return _buildPaperNote(
                          mood: mood,
                          description: description,
                          timeString: timeString,
                          timestamp: timestampString,
                          date: date,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: isToday
                      ? Row(
                          children: [
                            Expanded(
                              child: Button.secondary(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                text: 'Close',
                                size: ButtonSize.medium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Button.primary(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAddMoodDialog(date);
                                },
                                text: 'Add Note',
                                size: ButtonSize.medium,
                                leadingIcon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedAdd01,
                                  size: 18,
                                  strokeWidth: 2,
                                  color: AppTokens.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: Button.secondary(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            text: 'Close',
                            size: ButtonSize.medium,
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

  // Get color for mood
  Color _getMoodColor(int mood) {
    switch (mood) {
      case 0: // Very Sad
        return AppColors.pastelBlue;
      case 1: // Sad
        return AppColors.pastelBlue;
      case 2: // Neutral
        return const Color(0xFFE8E8E8); // Light grey
      case 3: // Happy
        return AppColors.pink40;
      case 4: // Very Happy
        return AppColors.pink40;
      default:
        return const Color(0xFFE8E8E8);
    }
  }

  // Helper method to build a single paper note
  Widget _buildPaperNote({
    required int mood,
    required String description,
    required String timeString,
    required String timestamp,
    required DateTime date,
  }) {
    final noteColor = _getMoodColor(mood);
    
    return GestureDetector(
      onTap: () => _showMoodEntryMenu(date, timestamp, mood, description),
      child: Container(
        width: (MediaQuery.of(context).size.width - 52) / 2, // Two columns with spacing
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: noteColor,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: noteColor.withAlpha(180), // Border matches note color
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(2, 3),
            ),
            BoxShadow(
              color: noteColor.withAlpha(80), // Shadow tinted with note color
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with mood icon and time
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/${_getMoodIconName(mood)}.svg',
                  width: 24,
                  height: 24,
                ),
                const Spacer(),
                Text(
                  timeString,
                  style: AppTokens.textStyleSmall.copyWith(
                    color: AppTokens.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Tape indicator
            Container(
              height: 1,
              width: 30,
              decoration: BoxDecoration(
                color: AppTokens.borderLight.withAlpha(100),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 10),
            // Description text
            Text(
              description,
              style: AppTokens.textStyleSmall.copyWith(
                color: AppTokens.textPrimary,
                height: 1.5,
                letterSpacing: 0.1,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ),
    );
  }

  // Show menu for mood entry actions (edit/delete)
  void _showMoodEntryMenu(DateTime date, String timestamp, int mood, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTokens.bgPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Edit option
                ListTile(
                  leading: const Icon(Icons.edit, color: AppTokens.iconBold),
                  title: const Text('Edit Note', style: AppTokens.textStyleMedium),
                  onTap: () {
                    Navigator.pop(context);
                    _editMoodEntry(date, timestamp, mood, description);
                  },
                ),
                
                // Delete option
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Delete Note',
                    style: AppTokens.textStyleMedium.copyWith(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMoodEntry(date, timestamp);
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Edit a mood entry
  void _editMoodEntry(DateTime date, String timestamp, int mood, String description) {
    // Close the current mood details sheet
    Navigator.pop(context);
    
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DailyMoodPrompt(
          date: date,
          initialMood: mood,
          initialDescription: description,
          isEditing: true,
          entryTimestamp: timestamp,
          onComplete: () async {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            setState(() {
              _moodRefreshKey++;
            });
          },
        );
      },
    );
  }

  // Delete a mood entry
  void _deleteMoodEntry(DateTime date, String timestamp) async {
    // Show confirmation in bottom modal
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTokens.bgPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTokens.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Title
                  Text(
                    'Delete Note',
                    style: AppTokens.textStyleXLarge.copyWith(
                      color: AppTokens.iconBold,
                      fontWeight: AppTokens.fontWeightBold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Message
                  Text(
                    'Are you sure you want to delete this mood note? This action cannot be undone.',
                    style: AppTokens.textStyleMedium.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Button.secondary(
                          onPressed: () => Navigator.pop(context, false),
                          text: 'Cancel',
                          size: ButtonSize.large,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Button.destructive(
                          onPressed: () => Navigator.pop(context, true),
                          text: 'Delete',
                          size: ButtonSize.large,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        await HiveService.deleteMoodEntry(date, timestamp);
        
        // Close the mood details sheet
        if (mounted) {
          Navigator.pop(context);
        }
        
        // Refresh the UI
        setState(() {
          _moodRefreshKey++;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mood note deleted')),
          );
        }
      } catch (e) {
        devPrint('Error deleting mood entry: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting mood note: $e')),
          );
        }
      }
    }
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

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DailyMoodPrompt(
          date: date, // Pass the selected date
          onComplete: () {
            Navigator.of(context).pop();
            setState(() {
              // Increment key to force mood widget refresh
              _moodRefreshKey++;
            });
          },
        );
      },
    );
  }

  Widget _buildMorningSection() {
    final List<IntakeLog> medications = medList.forMorning();

    return medications.isEmpty
        ? SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Morning', 'sunrise'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  return _buildMedicationItem(medications[index]);
                },
              ),
            ],
          );
  }

  Widget _buildNoonSection() {
    final List<IntakeLog> medications = medList.forNoon();

    return medications.isEmpty
        ? SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Noon', 'sun'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  return _buildMedicationItem(medications[index]);
                },
              ),
            ],
          );
  }

  Widget _buildAfternoonSection() {
    final List<IntakeLog> medications = medList.forAfternoon();

    return medications.isEmpty
        ? SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Afternoon', 'afternoon'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  return _buildMedicationItem(medications[index]);
                },
              ),
            ],
          );
  }

  Widget _buildEveningSection() {
    final List<IntakeLog> medications = medList.forEvening();

    return medications.isEmpty
        ? SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Evening', 'sunset'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  return _buildMedicationItem(medications[index]);
                },
              ),
            ],
          );
  }

  Widget _buildNightSection() {
    final List<IntakeLog> medications = medList.forNight();

    return medications.isEmpty
        ? SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Night', 'moon'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  return _buildMedicationItem(medications[index]);
                },
              ),
            ],
          );
  }

  Padding _buildSectionHeader(String title, String iconName) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: SvgPicture.asset(
              'assets/icons/$iconName.svg',
              width: 32,
              height: 32,
            ),
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: AppTokens.textStyleLarge,
          ),
        ],
      ),
    );
  }

  InkWell _buildMedicationItem(IntakeLog medicineLog) {
    final bool isTaken = medicineLog.isTaken;
    final bool isSkipped = medicineLog.isSkipped;
    final medication = medicineLog.treatment;
    final String name = medication.medicine.name;
    String type = medication.medicine.type.toLowerCase();
    final String dosage =
        '${medication.medicine.specs.dosage} ${medication.medicine.specs.unit}';
    // Use the specific dose time if available, otherwise fall back to treatment's general time
    final DateTime timeSource = medicineLog.doseTime ?? medication.treatmentPlan.timeOfDay;
    final String time = '${timeSource.hour.toString().padLeft(2, '0')}:${timeSource.minute.toString().padLeft(2, '0')}';
    final String color = medication.medicine.color;

    // Remove trailing 's' for plurals, but keep "drops" as is since it's not a plural
    if (type.endsWith('s') && type != 'drops') {
      type = type.substring(0, type.length - 1);
    }

    // Parse bicolore colors for capsules
    String primaryColor = color;
    String? secondaryColor;
    if (type == 'capsule' && color.contains('&')) {
      final parts = color.split('&');
      if (parts.length == 2) {
        primaryColor = parts[0].trim();
        secondaryColor = parts[1].trim();
      }
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
                    width: 40, height: 40, child: futureBuildSvg(type, primaryColor, 40, secondaryColor)),
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
                      child: Icon(Icons.check_circle,
                          color: Colors.green, size: 14),
                    ),
                  ),
                if (isSkipped)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.cancel, color: Colors.red, size: 14),
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
                    style: AppTokens.textStyleMedium.copyWith(
                      decoration: (isTaken || isSkipped)
                          ? TextDecoration.lineThrough
                          : null,
                      color: isSkipped ? Colors.red[600] : AppTokens.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dosage,
                    style: TextStyle(fontSize: 14, color: AppTokens.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Text(
              time,
              style: AppTokens.textStyleMedium,
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
      backgroundColor: AppTokens.buttonElevatedBg,
      elevation: 0,
      highlightElevation: 0,
      hoverElevation: 0, // removes shadow on hover
      focusElevation: 0, // removes shadow when focused
      disabledElevation: 0,
      shape: const CircleBorder(
        side: BorderSide(
          color: AppTokens.borderLight, // your desired border color
          width: 1, // border thickness
        ),
      ),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedAdd01,
        size: 24,
        strokeWidth: 1,
        color: AppTokens.iconPrimary,
      ),
    );
  }

  void _showAddPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTokens.bgPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              
              Text(
                'What do you want to add?',
                textAlign: TextAlign.center,
                style: AppTokens.textStyleLarge.copyWith(
                  fontWeight: AppTokens.fontWeightBold,
                ),
              ),
              SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: Button.primary(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/new_treatment');
                  },
                  text: 'New treatment',
                  size: ButtonSize.large,
                  leadingIcon: appVectorImage(fileName: 'treatment', size: 28),
                ),
              ),
              SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: Button.secondary(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/one_time_take');
                  },
                  text: 'One-time take',
                  size: ButtonSize.large,
                  leadingIcon: appVectorImage(fileName: 'pills', size: 28),
                  borderWidth: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _showMedicationDetails(IntakeLog medicineLog) {
    final medication = medicineLog.treatment;
    final String name = medication.medicine.name;
    final String dosage =
        '${medication.medicine.specs.dosage} ${medication.medicine.specs.unit}';
    final bool isTaken = medicineLog.isTaken;
    final bool isSkipped = medicineLog.isSkipped;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTokens.bgPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTokens.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$name • $dosage',
                          style: AppTokens.textStyleXLarge,
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          // Navigate to edit treatment screen and wait for result
                          await context.push('/edit_treatment', extra: medication);
                          // Refresh journal data when returning from edit screen
                          if (mounted) {
                            await _refreshJournalData();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit02,
                            color: AppTokens.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    _getScheduleDescription(medication),
                    style: AppTokens.textStyleMedium.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      // Parse bicolore colors for capsules
                      String colorString = medication.medicine.color;
                      String primaryColor = colorString;
                      String? secondaryColor;
                      if (medication.medicine.type.toLowerCase() == 'capsule' && colorString.contains('&')) {
                        final parts = colorString.split('&');
                        if (parts.length == 2) {
                          primaryColor = parts[0].trim();
                          secondaryColor = parts[1].trim();
                        }
                      }
                      
                      return _buildInfoItemWithIcon(
                        _getColorDescription(medication.medicine.color, medication.medicine.type),
                        _getTreatmentTypeIcon(medication.medicine.type, primaryColor, secondaryColor: secondaryColor),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      // Parse bicolore colors for meal option icons
                      String colorString = medication.medicine.color;
                      String primaryColor = colorString;
                      String? secondaryColor;
                      if (medication.medicine.type.toLowerCase() == 'capsule' && colorString.contains('&')) {
                        final parts = colorString.split('&');
                        if (parts.length == 2) {
                          primaryColor = parts[0].trim();
                          secondaryColor = parts[1].trim();
                        }
                      }
                      
                      final mealOption = medication.treatmentPlan.mealOption.isNotEmpty
                          ? medication.treatmentPlan.mealOption
                          : 'Never mind';
                      
                      return _buildInfoItemWithIcon(
                        medication.treatmentPlan.mealOption.isNotEmpty
                            ? _getMealOptionLabel(medication.treatmentPlan.mealOption)
                            : 'No preference',
                        _getMealOptionIcon(
                          mealOption,
                          primaryColor,
                          secondaryColor: secondaryColor,
                        ),
                      );
                    },
                  ),
                  if (medication.treatmentPlan.instructions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoItem(medication.treatmentPlan.instructions),
                  ],
                  const SizedBox(height: 24),

              // Show status if pill is taken or skipped, otherwise show action buttons
              if (isTaken || isSkipped) ...[
                // Status display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isTaken ? AppTokens.stateSuccess.withValues(alpha: 0.1) : AppTokens.stateError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isTaken ? Icons.check_circle : Icons.cancel,
                        color: isTaken ? AppTokens.stateSuccess : AppTokens.stateError,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTaken ? 'Pill taken!' : 'Pill skipped!',
                          style: AppTokens.textStyleMedium.copyWith(
                            color: isTaken ? AppTokens.stateSuccess : AppTokens.stateError,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Cancel action button
                Button.secondary(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    navigator.pop();

                    // Reset to neutral state
                    final pillIntakeNotifier =
                        ref.read(pillIntakeProvider.notifier);
                    await pillIntakeNotifier.cancelPillAction(
                        medicineLog, selectedDate);

                    if (mounted) {
                      setState(() {
                        devPrint(
                            'Action cancelled: taken=${medicineLog.isTaken}, skipped=${medicineLog.isSkipped}');
                      });
                    }
                  },
                  text: 'Cancel action',
                  size: ButtonSize.large,
                  borderWidth: 0,
                ),
              ] else ...[
                // Action buttons for untaken pills
                Row(
                  children: [
                    Expanded(
                      child: Button.destructive(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          navigator.pop();

                          // Get the pill intake notifier and use the async version of pillSkipped
                          final pillIntakeNotifier =
                              ref.read(pillIntakeProvider.notifier);
                          await pillIntakeNotifier.pillSkipped(
                              medicineLog, selectedDate);

                          if (mounted && context.mounted) {
                            _showPillSkippedDialog(context);
                            setState(() {
                              // Log for debugging
                              devPrint(
                                  'Pill skipped: ${medicineLog.isSkipped}');
                            });
                          }
                        },
                        text: 'Skip for today',
                        size: ButtonSize.small,
                        borderRadius:
                            50, // Full radius for pill-like appearance
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Button.primary(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          navigator.pop();

                          // Get the pill intake notifier and use the async version of pillTaken
                          final pillIntakeNotifier =
                              ref.read(pillIntakeProvider.notifier);
                          await pillIntakeNotifier.pillTaken(
                            medicineLog,
                            selectedDate,
                            ref,
                          );

                          if (mounted && context.mounted) {
                            _showPillTakenDialog(context);
                            setState(() {
                              // Log for debugging
                              devPrint('Pill taken: ${medicineLog.isTaken}');
                            });
                          }
                        },
                        text: 'Take pill',
                        size: ButtonSize.small,
                        borderRadius: 50, // Full radius to match skip button
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Postpone',
                      style: AppTokens.textStyleSmall.copyWith(
                        color: AppTokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
                ],
              ),
            ),
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
                  fontWeight: AppTokens.fontWeightBold,
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppTokens.buttonPrimaryBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: AppTokens.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showPillSkippedDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cancel,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                'Pill skipped!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: AppTokens.fontWeightBold,
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppTokens.buttonPrimaryBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: AppTokens.textPrimary,
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

  String _getColorDescription(String color, String type) {
    // Check if the color string contains bicolore information
    // This is a simple approach - in a real implementation, you'd want to store secondary colors properly
    if (type.toLowerCase() == 'capsule' && color.contains('&')) {
      // If color contains '&', it means it's bicolore (e.g., "Blue & Pink")
      return '${color.capitalize()} $type';
    } else {
      // Regular single color
      return '${color.capitalize()} $type';
    }
  }

  String _formatDuration(DateTime startDate, DateTime endDate) {
    final duration = endDate.difference(startDate).inDays + 1;
    
    // Check if it's an ongoing treatment (duration > 50 years indicates unlimited)
    final durationYears = duration / 365.0;
    if (durationYears > 50) {
      return 'ongoing treatment';
    }
    
    if (duration == 1) {
      return '1 day';
    } else if (duration < 7) {
      return '$duration days';
    } else if (duration < 30) {
      final weeks = (duration / 7).round();
      return weeks == 1 ? '1 week' : '$weeks weeks';
    } else {
      final months = (duration / 30).round();
      return months == 1 ? '1 month' : '$months months';
    }
  }

  String _getScheduleDescription(Treatment medication) {
    // Get all dose times for this treatment
    final doseTimes = medication.treatmentPlan.getAllDoseTimes();
    String timeStr;
    if (doseTimes.length == 1) {
      final time = doseTimes[0];
      timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // Multiple doses per day - show all times
      final times = doseTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList();
      timeStr = times.join(', ');
    }
    
    final duration = _formatDuration(
        medication.treatmentPlan.startDate, medication.treatmentPlan.endDate);

    // Get selected days
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = medication.treatmentPlan.selectedDays;
    final activeDays = <String>[];
    for (int i = 0; i < 7; i++) {
      if (selectedDays[i]) {
        activeDays.add(days[i]);
      }
    }

    String daysStr;
    if (activeDays.length == 7) {
      daysStr = 'every day';
    } else if (activeDays.length == 1) {
      daysStr = activeDays[0];
    } else if (activeDays.length <= 3) {
      daysStr = activeDays.join(', ');
    } else {
      daysStr = '${activeDays.length} days/week';
    }

    // Check if it's an ongoing treatment (duration > 50 years indicates unlimited)
    final durationDays = medication.treatmentPlan.endDate.difference(medication.treatmentPlan.startDate).inDays + 1;
    final durationYears = durationDays / 365.0;
    final isOngoing = durationYears > 50;

    if (isOngoing) {
      return '$daysStr at $timeStr';
    } else {
      return '$daysStr at $timeStr for $duration';
    }
  }

  Widget _buildInfoItem(String text) {
    return Row(
      children: [
        Icon(Icons.check, color: AppTokens.stateSuccess, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTokens.textStyleMedium.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItemWithIcon(String text, Widget iconWidget) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: iconWidget,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTokens.textStyleMedium,
          ),
        ),
      ],
    );
  }

  Widget _getTreatmentTypeIcon(String type, String color, {String? secondaryColor}) {
    final iconFile = type.toLowerCase();
    final primaryColorValue = colorMap[color.trim()];
    final secondaryColorValue = secondaryColor != null ? colorMap[secondaryColor.trim()] : null;
    
    if (primaryColorValue != null) {
      return FutureBuilder<SvgPicture>(
        future: appSvgDynamicImage(
          fileName: iconFile,
          size: 48,
          color: primaryColorValue,
          secondaryColor: secondaryColorValue,
          useColorFilter: false,
        ),
        builder: (context, snapshot) {
          return snapshot.data ?? appVectorImage(
            fileName: iconFile,
            size: 48,
            color: primaryColorValue,
            useColorFilter: false,
          );
        },
      );
    }
    return appVectorImage(fileName: iconFile, size: 48);
  }

  Widget _getMealOptionIcon(String mealOption, String color, {String? secondaryColor}) {
    // Map meal options to icon file names
    String iconFile;
    switch (mealOption.toLowerCase()) {
      case 'before meal':
        iconFile = 'before-meal';
        break;
      case 'after meal':
        iconFile = 'after-meal';
        break;
      case 'with food':
        iconFile = 'with-food';
        break;
      case 'never mind':
      case 'no preference':
      default:
        iconFile = 'never-mind';
        break;
    }
    
    final primaryColorValue = colorMap[color.trim()];
    final secondaryColorValue = secondaryColor != null ? colorMap[secondaryColor.trim()] : null;
    
    if (primaryColorValue != null) {
      return FutureBuilder<SvgPicture>(
        future: appSvgDynamicImage(
          fileName: iconFile,
          size: 48,
          color: primaryColorValue,
          secondaryColor: secondaryColorValue,
          useColorFilter: false,
        ),
        builder: (context, snapshot) {
          return snapshot.data ?? appVectorImage(
            fileName: iconFile,
            size: 48,
            color: primaryColorValue,
            useColorFilter: false,
          );
        },
      );
    }
    return appVectorImage(fileName: iconFile, size: 48);
  }

  String _getMealOptionLabel(String mealOption) {
    // Return a cleaner label
    return mealOption.isNotEmpty ? mealOption : 'Take as directed';
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

String getMoodEmoji(int mood) {
  switch (mood) {
    case 0:
      return '😭'; // Very Sad (crying face with tears)
    case 1:
      return '🙁'; // Sad (slightly frowning face)
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
