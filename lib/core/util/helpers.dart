import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pinkrain/core/util/date_format_converters.dart';

import '../../features/journal/data/journal_log.dart';
import '../theme/icons.dart';
import '../widgets/color_picker.dart';

extension StringExtensions on String {
  void logType(){
    devPrint(runtimeType);
  }
  void log(){
    devPrint(this);
  }
  /// Returns the debug value if debug mode is enabled, otherwise returns the original value
  String debugValue(String? val){
    if(kDebugMode){
      return val ?? this;
    }
    else{
      return this;
    }

  }
}

void devPrint(dynamic message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Create a DateTime object for time-of-day only (date portion is arbitrary and consistent)
/// This ensures all time-of-day comparisons work correctly regardless of actual date
DateTime createTimeOfDay(int hour, int minute) {
  // Use Unix epoch (1970-01-01) as the arbitrary date for all time-of-day values
  // This ensures consistency across all time comparisons
  return DateTime(1970, 1, 1, hour, minute);
}

extension DateTimeExtensions on DateTime {
  DateTime normalize() {
    return DateTime(year, month, day);
  }
  String getNameOf(String selectedDateOption) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDate = DateTime(year, month, day);
    
    switch(selectedDateOption) {
      case 'week':
        // Get start of week (Monday)
        final weekday = thisDate.weekday; // 1 = Monday, 7 = Sunday
        final daysToSubtract = weekday - 1;
        final startOfWeek = DateTime(thisDate.year, thisDate.month, thisDate.day)
            .subtract(Duration(days: daysToSubtract));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        
        // Check if this week contains today
        if (startOfWeek.isBefore(today) || startOfWeek.isAtSameMomentAs(today)) {
          if (endOfWeek.isAfter(today) || endOfWeek.isAtSameMomentAs(today)) {
            return 'This Week';
          }
        }
        
        // Format week range
        if (startOfWeek.month == endOfWeek.month) {
          return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('d').format(endOfWeek)}';
        } else {
          return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}';
        }
      case 'month':
        return getMonthName(month);
      case 'year':
        return '$year';
    }
    return '';
  }
    bool isToday() => day == DateTime.now().day && month == DateTime.now().month && year == DateTime.now().year;
}

extension ListExtensions on List<IntakeLog> {
  List<IntakeLog> forMorning() {
    final list = where((t) {
      // Use the specific dose time if available, otherwise fall back to treatment's general time
      final time = t.doseTime ?? t.treatment.treatmentPlan.timeOfDay;
      return time.hour >= 0 && time.hour < 12;
    }).toList();
    list.sort((a, b) {
      final timeA = a.doseTime ?? a.treatment.treatmentPlan.timeOfDay;
      final timeB = b.doseTime ?? b.treatment.treatmentPlan.timeOfDay;
      return timeA.compareTo(timeB);
    });
    return list;
  }

  List<IntakeLog> forNoon() {
    final list = where((t) {
      final time = t.doseTime ?? t.treatment.treatmentPlan.timeOfDay;
      return time.hour >= 12 && time.hour < 14;
    }).toList();
    list.sort((a, b) {
      final timeA = a.doseTime ?? a.treatment.treatmentPlan.timeOfDay;
      final timeB = b.doseTime ?? b.treatment.treatmentPlan.timeOfDay;
      return timeA.compareTo(timeB);
    });
    return list;
  }

  List<IntakeLog> forAfternoon() {
    final list = where((t) {
      final time = t.doseTime ?? t.treatment.treatmentPlan.timeOfDay;
      return time.hour >= 14 && time.hour < 18;
    }).toList();
    list.sort((a, b) {
      final timeA = a.doseTime ?? a.treatment.treatmentPlan.timeOfDay;
      final timeB = b.doseTime ?? b.treatment.treatmentPlan.timeOfDay;
      return timeA.compareTo(timeB);
    });
    return list;
  }

  List<IntakeLog> forEvening() {
    final list = where((t) {
      final time = t.doseTime ?? t.treatment.treatmentPlan.timeOfDay;
      return time.hour >= 18 && time.hour < 21;
    }).toList();
    list.sort((a, b) {
      final timeA = a.doseTime ?? a.treatment.treatmentPlan.timeOfDay;
      final timeB = b.doseTime ?? b.treatment.treatmentPlan.timeOfDay;
      return timeA.compareTo(timeB);
    });
    return list;
  }

  List<IntakeLog> forNight() {
    final list = where((t) {
      final time = t.doseTime ?? t.treatment.treatmentPlan.timeOfDay;
      return time.hour >= 21;
    }).toList();
    list.sort((a, b) {
      final timeA = a.doseTime ?? a.treatment.treatmentPlan.timeOfDay;
      final timeB = b.doseTime ?? b.treatment.treatmentPlan.timeOfDay;
      return timeA.compareTo(timeB);
    });
    return list;
  }
}

// Extension to add date comparison functionality
extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

// Extension to add string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension IntExtension on int {
  String ordinal() {
    final dateInt = this % 10;
    return "$this${
        dateInt == 1 ? 'st' : dateInt == 2 ? 'nd' : dateInt == 3 ? 'rd' : 'th'
    }";
  }
}

// Use the centralized colorMap from ColorPicker widget
final Map<String, Color> colorMap = ColorPicker.colorMap;


FutureBuilder<SvgPicture> futureBuildSvg(String text, String? selectedColor, [double size = 30, String? secondaryColor]) {
  // Use 'White' as default when selectedColor is null
  final String effectiveColor = selectedColor ?? 'White';
  return FutureBuilder<SvgPicture>(
      future: appSvgDynamicImage(
          fileName: text.toLowerCase(),
          size: size,
          color: colorMap[effectiveColor],
          secondaryColor: secondaryColor != null ? colorMap[secondaryColor] : null,
          useColorFilter: false
      ),
      builder: (context, snapshot) {
        return snapshot.data ??
            appVectorImage(
                fileName: text.toLowerCase(),
                size: size,
                color: colorMap[effectiveColor],
                useColorFilter: false
            );
      }
  );
}

DateTime getStartDate(String selectedDateOption, DateTime selectedDate) {
  DateTime startDate;
  switch (selectedDateOption) {
    case 'week':
      // For a week, get the start of the week (Monday)
      final weekday = selectedDate.weekday; // 1 = Monday, 7 = Sunday
      final daysToSubtract = weekday - 1; // Days to subtract to get to Monday
      startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
          .subtract(Duration(days: daysToSubtract));
      break;
    case 'month':
      // For a month, use the first day of the month to the selected date
      startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      break;
    case 'year':
      // For a year, use the first day of the year to the selected date
      startDate = DateTime(selectedDate.year, 1, 1);
      break;
    default:
      // Default to last 30 days
      startDate = selectedDate.subtract(const Duration(days: 30));
  }
  return startDate;
}