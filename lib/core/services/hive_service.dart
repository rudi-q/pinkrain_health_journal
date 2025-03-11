import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class HiveService {
  static const String userPrefsBox = 'userPreferences';
  static const String lastMoodDateKey = 'lastMoodDate';
  static const String userMoodKey = 'userMood';
  static const String userMoodDescriptionKey = 'userMoodDescription';

  /// Initialize Hive
  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    // Open boxes
    await Hive.openBox(userPrefsBox);
  }

  /// Check if this is the first launch of the day
  static bool isFirstLaunchOfDay() {
    final box = Hive.box(userPrefsBox);
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? lastDate = box.get(lastMoodDateKey);
    
    // If no date is stored or the stored date is different from today
    return lastDate == null || lastDate != today;
  }

  /// Set today as the last mood entry date
  static Future<void> setMoodEntryForToday() async {
    final box = Hive.box(userPrefsBox);
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await box.put(lastMoodDateKey, today);
  }

  /// Save user's daily mood data
  static Future<void> saveUserMood(int moodValue, String moodDescription) async {
    final box = Hive.box(userPrefsBox);
    await box.put(userMoodKey, moodValue);
    await box.put(userMoodDescriptionKey, moodDescription);
    await setMoodEntryForToday();
  }

  /// Get user's mood value
  static int? getUserMood() {
    final box = Hive.box(userPrefsBox);
    return box.get(userMoodKey);
  }

  /// Get user's mood description
  static String? getUserMoodDescription() {
    final box = Hive.box(userPrefsBox);
    return box.get(userMoodDescriptionKey);
  }
  
  /// Get the date of the last mood entry
  static String? getLastMoodDate() {
    final box = Hive.box(userPrefsBox);
    return box.get(lastMoodDateKey);
  }
}
