import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pillow/core/util/dateFormatConverters.dart';

import '../../features/journal/data/journal_log.dart';
import '../theme/icons.dart';

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

void devPrint(var message) {
  if (kDebugMode) {
    print(message);
  }
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
      case 'day':
        if (thisDate.isAtSameMomentAs(today)) {
          return 'Today';
        } else {
          return DateFormat('MMMM d, yyyy').format(this);
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
  List<IntakeLog> forEvening() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour >= 14).toList();
  }

  List<IntakeLog> forMorning() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour <= 12).toList();
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

final Map<String, Color> colorMap = {
  'White': Colors.white,
  'Yellow': Color(0xFFFFF3C4), // Soft pastel yellow
  'Pink': Color(0xFFFFE4E8),   // Soft pastel pink
  'Blue': Color(0xFFE3F2FD),   // Soft pastel blue
  'Red': Color(0xFFFFE5E5),    // Soft pastel red
};


FutureBuilder<SvgPicture> futureBuildSvg(String text, selectedColor, [double size = 30]) {
  return FutureBuilder<SvgPicture>(
      future: appSvgDynamicImage(
          fileName: text.toLowerCase(),
          size: size,
          color: colorMap[selectedColor],
          useColorFilter: false
      ),
      builder: (context, snapshot) {
        return snapshot.data ??
            appVectorImage(
                fileName: text.toLowerCase(),
                size: size,
                color: colorMap[selectedColor],
                useColorFilter: false
            );
      }
  );
}

DateTime getStartDate(String selectedDateOption, DateTime selectedDate) {
  DateTime startDate;
  switch (selectedDateOption) {
    case 'day':
    // For a day, just use the selected date
      startDate = selectedDate;
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