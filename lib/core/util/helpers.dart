import 'package:flutter/foundation.dart';

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
