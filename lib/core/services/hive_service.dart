import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pillow/core/util/helpers.dart' show devPrint;
import 'package:pillow/features/treatment/domain/treatment_manager.dart' show generateUniqueId;

class HiveService {
  static const String userPrefsBox = 'userPreferences';
  static const String moodBoxName = 'moodData';
  static const String symptomBoxName = 'symptomData';
  static const String medicationLogsBoxName = 'medicationLogs';
  static const String treatmentsBoxName = 'treatments';
  static const String lastMoodDateKey = 'lastMoodDate';
  static const String userMoodKey = 'userMood';
  static const String userMoodDescriptionKey = 'userMoodDescription';

  /// Initialize Hive
  static Future<void> init() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);

      // Open boxes
      await _openBox(userPrefsBox);
      await _openBox(moodBoxName);
      await _openBox(symptomBoxName);
      await _openBox(medicationLogsBoxName);
      await _openBox(treatmentsBoxName);
    } catch (e) {
      devPrint('Error initializing Hive: $e');
    }
  }

  /// Helper method to safely open a box
  static Future<Box> _openBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      } else {
        return await Hive.openBox(boxName);
      }
    } catch (e) {
      devPrint('Error opening box $boxName: $e');
      // Create a new box if there was an error
      await Hive.deleteBoxFromDisk(boxName);
      return await Hive.openBox(boxName);
    }
  }

  /// Check if this is the first launch of the day
  static Future<bool> isFirstLaunchOfDay() async {
    try {
      final box = await _openBox(userPrefsBox);
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String? lastDate = await box.get(lastMoodDateKey);

      // If no date is stored or the stored date is different from today
      return lastDate == null || lastDate != today;
    } catch (e) {
      devPrint('Error checking first launch: $e');
      return true; // Default to true if there's an error
    }
  }

  /// Set today as the last mood entry date
  static Future<void> setMoodEntryForToday() async {
    try {
      final box = await _openBox(userPrefsBox);
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await box.put(lastMoodDateKey, today);
    } catch (e) {
      devPrint('Error setting mood entry for today: $e');
    }
  }

  /// Save user mood data
  static Future<void> saveUserMood(int mood, String description) async {
    try {
      final box = await _openBox(userPrefsBox);

      // Save the current date
      final now = DateTime.now().toIso8601String();
      await box.put(lastMoodDateKey, now);

      // Save the mood data
      await box.put(userMoodKey, mood);
      await box.put(userMoodDescriptionKey, description);
    } catch (e) {
      devPrint('Error saving user mood: $e');
    }
  }

  /// Get user mood
  static Future<int> getUserMood() async {
    try {
      final box = await _openBox(userPrefsBox);
      return await box.get(userMoodKey, defaultValue: 2);
    } catch (e) {
      devPrint('Error getting user mood: $e');
      return 2; // Default to neutral mood
    }
  }

  /// Get user mood description
  static Future<String> getUserMoodDescription() async {
    try {
      final box = await _openBox(userPrefsBox);
      return await box.get(userMoodDescriptionKey, defaultValue: '');
    } catch (e) {
      devPrint('Error getting user mood description: $e');
      return ''; // Default to empty string
    }
  }

  /// Get last mood date
  static Future<String?> getLastMoodDate() async {
    try {
      final box = await _openBox(userPrefsBox);
      return await box.get(lastMoodDateKey);
    } catch (e) {
      devPrint('Error getting last mood date: $e');
      return null;
    }
  }

  // Get mood data for a specific date
  static Future<Map<String, dynamic>?> getMoodForDate(DateTime date) async {
    try {
      final box = await _openBox(moodBoxName);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final moodData = await box.get('mood_$dateKey');
      return moodData != null ? Map<String, dynamic>.from(moodData) : null;
    } catch (e) {
      devPrint('Error getting mood data: $e');
      return null;
    }
  }

  // Check if mood data exists for a specific date
  static Future<bool> hasMoodForDate(DateTime date) async {
    try {
      final box = await _openBox(moodBoxName);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      return box.containsKey('mood_$dateKey');
    } catch (e) {
      devPrint('Error checking mood data: $e');
      return false;
    }
  }

  // Save mood data for a specific date
  static Future<void> saveMoodForDate(
      DateTime date, int mood, String description) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen(moodBoxName)) {
        await Hive.openBox(moodBoxName);
      }
      final box = Hive.box(moodBoxName);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      // Save the mood data
      await box.put('mood_$dateKey', {
        'mood': mood,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // If it's today, also update current mood
      final today = DateTime.now();
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      if (isToday) {
        await saveUserMood(mood, description);
        await setMoodEntryForToday();
      }

      devPrint(
          'Successfully saved mood $mood with description "$description" for date $dateKey');
    } catch (e) {
      devPrint('Error saving mood data for date: $e');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  /// Save a symptom entry
  static Future<void> saveSymptom(String symptom, DateTime date) async {
    try {
      final box = await _openBox(symptomBoxName);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      List<String> existingSymptoms = [];
      final existing = box.get(dateKey);
      if (existing != null) {
        existingSymptoms = List<String>.from(existing['symptoms']);
      }

      if (!existingSymptoms.contains(symptom)) {
        existingSymptoms.add(symptom);
      }

      await box.put(dateKey, {
        'date': dateKey,
        'symptoms': existingSymptoms,
      });
    } catch (e) {
      devPrint('Error saving symptom: $e');
    }
  }

  /// Get symptom entries for a date range
  static Future<List<SymptomEntry>> getSymptomEntries(
      DateTime start, DateTime end) async {
    try {
      final box = await _openBox(symptomBoxName);
      final entries = <SymptomEntry>[];

      // Convert dates to string format for comparison
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);

      for (var key in box.keys) {
        // Skip non-date keys if any
        if (key is! String || !key.contains('-')) continue;

        // Skip entries outside date range
        if (key.compareTo(startStr) < 0 || key.compareTo(endStr) > 0) continue;

        final entry = box.get(key);
        if (entry != null) {
          entries.add(SymptomEntry(
            date: DateTime.parse(entry['date']),
            symptoms: List<String>.from(entry['symptoms']),
          ));
        }
      }

      return entries;
    } catch (e) {
      devPrint('Error getting symptom entries: $e');
      return [];
    }
  }

  /// Get correlation data between medication adherence and mood
  /// Returns a list of data points where each point contains:
  /// - x: medication adherence percentage (0-100)
  /// - y: mood level (1-5)
  /// - date: the date of the data point
  static Future<List<Map<String, dynamic>>> getMedicationMoodCorrelation({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final List<Map<String, dynamic>> correlationData = [];

      // Get all dates in the range
      final daysInRange = endDate.difference(startDate).inDays + 1;

      for (int i = 0; i < daysInRange; i++) {
        final date = startDate.add(Duration(days: i));

        // Get mood data for this date
        final moodData = await getMoodForDate(date);

        // Only proceed if we have mood data
        if (moodData != null && moodData.containsKey('mood')) {
          final moodValue = moodData['mood'] as int;

          // Get medication logs for this date
          final medicationLogs = await getMedicationLogsForDate(date);

          if (medicationLogs != null && medicationLogs.isNotEmpty) {
            // Calculate adherence percentage
            int totalMeds = medicationLogs.length;
            int takenMeds =
                medicationLogs.where((log) => log['taken'] == true).length;

            // Avoid division by zero
            double adherencePercentage =
                totalMeds > 0 ? (takenMeds / totalMeds) * 100 : 0;

            // Add data point
            correlationData.add({
              'x': adherencePercentage,
              'y': moodValue.toDouble(),
              'date': date,
            });
          }
        }
      }

      return correlationData;
    } catch (e) {
      devPrint('Error getting medication-mood correlation: $e');
      return [];
    }
  }

  /// Get medication logs for a specific date
  static Future<List<Map<String, dynamic>>?> getMedicationLogsForDate(
      DateTime date) async {
    try {
      final box = await _openBox(medicationLogsBoxName);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final logs = await box.get('logs_$dateKey');
      if (logs == null) return null;

      // Cast each map in the list to Map<String, dynamic>
      return (logs as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      devPrint('Error getting medication logs: $e');
      return null;
    }
  }

  /// Save medication logs for a specific date
  static Future<void> saveMedicationLogsForDate(
      DateTime date, List<Map<String, dynamic>> logs) async {
    try {
      final box = await _openBox(medicationLogsBoxName);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      await box.put('logs_$dateKey', logs);
      devPrint('Successfully saved medication logs for date $dateKey');
      devPrint('Stored value: ${box.get('logs_$dateKey')}');
    } catch (e) {
      devPrint('Error saving medication logs: $e');
      rethrow;
    }
  }

  /// Save a treatment
  static Future<void> saveTreatment(Map<String, dynamic> treatment) async {
    try {
      final box = await _openBox(treatmentsBoxName);
      final treatments = await getTreatments();
      treatments.add(treatment);
      // Sanitize and store
      final sanitizedList = _sanitizeList(treatments);
      await box.put('treatments', sanitizedList);
    } catch (e) {
      devPrint('Error saving treatment: $e');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  /// Update a treatment
  static Future<void> updateTreatment(Map<String, dynamic> oldTreatment, Map<String, dynamic> updatedTreatment) async {
    try {
      final box = await _openBox(treatmentsBoxName);
      final treatments = await getTreatments();
      
      // CRITICAL ID FIX: Ensure the updated treatment has a valid ID
      if (!updatedTreatment.containsKey('id') || updatedTreatment['id'] == null || updatedTreatment['id'].toString().isEmpty) {
        // If old treatment had an ID, use it
        if (oldTreatment.containsKey('id') && oldTreatment['id'] != null && oldTreatment['id'].toString().isNotEmpty) {
          updatedTreatment['id'] = oldTreatment['id'];
          devPrint("Preserved existing ID from old treatment: ${oldTreatment['id']}");
        } else {
          // Otherwise generate a new one
          updatedTreatment['id'] = generateUniqueId();
          devPrint("Created new ID for treatment without ID: ${updatedTreatment['id']}");
        }
      }
      
      // Find the index by matching all fields (or you can refine this to use only unique fields)
      final index = treatments.indexWhere((t) => _treatmentEquals(t, oldTreatment));
      if (index != -1) {
        devPrint("Updating treatment at index $index with ID: ${updatedTreatment['id']}");
        treatments[index] = updatedTreatment;
        // Sanitize and store
        final sanitizedList = _sanitizeList(treatments);
        await box.put('treatments', sanitizedList);
      } else {
        devPrint('Treatment to update not found.');
      }
    } catch (e) {
      devPrint('Error updating treatment: $e');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  /// Delete a treatment
  static Future<void> deleteTreatment(Map<String, dynamic> treatment) async {
    try {
      final box = await _openBox(treatmentsBoxName);
      final treatments = await getTreatments();
      
      // Find the index of the treatment to delete
      final index = treatments.indexWhere((t) => _treatmentEquals(t, treatment));
      
      if (index != -1) {
        // Remove the treatment from the list
        treatments.removeAt(index);
        
        // Sanitize and store the updated list
        final sanitizedList = _sanitizeList(treatments);
        await box.put('treatments', sanitizedList);
        devPrint('Successfully deleted treatment');
      } else {
        devPrint('Treatment to delete not found.');
      }
    } catch (e) {
      devPrint('Error deleting treatment: $e');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  /// Helper to compare two treatments (by ID with name fallback)
  static bool _treatmentEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    try {
      // First try to match by ID (preferred method)
      if (a['id'] != null && b['id'] != null) {
        final aId = a['id'].toString();
        final bId = b['id'].toString();
        
        if (aId.isNotEmpty && bId.isNotEmpty) {
          devPrint("Comparing treatments by ID: $aId vs $bId");
          return aId == bId;
        }
      }
      
      // Fallback to medicine name comparison (for backward compatibility)
      if (a['medicine'] == null || b['medicine'] == null) {
        devPrint("Treatment comparison failed due to missing main keys.");
        return false;
      }
      
      // Compare by medicine name as fallback
      final aMedicineName = a['medicine']['name']?.toString().toLowerCase();
      final bMedicineName = b['medicine']['name']?.toString().toLowerCase();
      
      if (aMedicineName == null || bMedicineName == null) {
        devPrint("Treatment comparison failed due to missing medicine name.");
        return false;
      }
      
      devPrint("Comparing treatments by name: $aMedicineName vs $bMedicineName");
      return aMedicineName == bMedicineName;
    } catch (e) {
      devPrint("Error in treatment comparison: $e");
      return false;
    }
  }

  /// Get all treatments
  static Future<List<Map<String, dynamic>>> getTreatments() async {
    try {
      final box = await _openBox(treatmentsBoxName);
      final dynamic raw = await box.get('treatments', defaultValue: []);
      final List rawList = raw as List;
      // Use consistent sanitization approach
      return _sanitizeList(rawList).cast<Map<String, dynamic>>();
    } catch (e) {
      devPrint('Error getting treatments: $e');
      return [];
    }
  }

  /// Helper method to sanitize maps for consistent storage/retrieval
  static Map<String, dynamic> _sanitizeMap(Map<dynamic, dynamic> map) {
    return Map<String, dynamic>.fromEntries(
      map.entries.map((entry) {
        final key = entry.key.toString();
        final value = entry.value;
        
        if (value is Map) {
          return MapEntry(key, _sanitizeMap(value as Map<dynamic, dynamic>));
        } else if (value is List) {
          return MapEntry(key, _sanitizeList(value));
        } else {
          return MapEntry(key, value);
        }
      }),
    );
  }
  
  /// Helper method to sanitize lists that may contain maps
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _sanitizeMap(item as Map<dynamic, dynamic>);
      } else if (item is List) {
        return _sanitizeList(item);
      } else {
        return item;
      }
    }).toList();
  }
}

/// Model class for symptom entries
class SymptomEntry {
  final DateTime date;
  final List<String> symptoms;

  SymptomEntry({
    required this.date,
    required this.symptoms,
  });
}
