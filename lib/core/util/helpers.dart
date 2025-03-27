import 'package:flutter/foundation.dart';
import 'package:pillow/core/util/dateFormatConverters.dart';
import 'package:intl/intl.dart';

import '../../features/journal/data/journal_log.dart';

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