import 'package:flutter/foundation.dart';

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
}

extension ListExtensions on List<IntakeLog> {
  List<IntakeLog> forEvening() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour >= 14).toList();
  }

  List<IntakeLog> forMorning() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour <= 12).toList();
  }
}

