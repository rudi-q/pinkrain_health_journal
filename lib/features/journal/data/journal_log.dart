import 'package:intl/intl.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/core/util/helpers.dart';

import '../../../core/models/medicine_model.dart';
import '../../treatment/data/treatment.dart';
import '../../treatment/domain/treatment_manager.dart';

class IntakeLog {
  final Treatment treatment;
  bool isTaken;

  IntakeLog(this.treatment, {this.isTaken = false});

  /// Convert IntakeLog to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'medicine_name': treatment.medicine.name,
      'medicine_type': treatment.medicine.type,
      'medicine_color': treatment.medicine.color,
      'dosage': treatment.medicine.specs.dosage,
      'unit': treatment.medicine.specs.unit,
      'is_taken': isTaken,
    };
  }

  /// Create IntakeLog from a Map
  static IntakeLog fromMap(Map<String, dynamic> map) {
    try {
      // Extract fields with safe defaults
      final dynamic nameValue = map['medicine_name'];
      final dynamic typeValue = map['medicine_type'];
      final dynamic colorValue = map['medicine_color'];
      final dynamic dosageValue = map['dosage'];
      final dynamic unitValue = map['unit'];
      final dynamic isTakenValue = map['is_taken'];

      // Convert name, type, and color with safe defaults
      final String name =
          (nameValue is String) ? nameValue : 'Unknown Medicine';
      final String type = (typeValue is String) ? typeValue : 'pill';
      final String color = (colorValue is String) ? colorValue : 'white';

      // Convert dosage with safe default
      double dosage = 1.0;
      if (dosageValue != null) {
        if (dosageValue is int) {
          dosage = dosageValue.toDouble();
        } else if (dosageValue is double) {
          dosage = dosageValue;
        } else if (dosageValue is String &&
            double.tryParse(dosageValue) != null) {
          dosage = double.parse(dosageValue);
        }
      }

      // Convert unit with safe default
      final String unit = (unitValue is String) ? unitValue : 'mg';

      // Check if already taken
      bool taken = false;
      if (isTakenValue != null) {
        if (isTakenValue is bool) {
          taken = isTakenValue;
        } else if (isTakenValue is int) {
          taken = isTakenValue != 0;
        } else if (isTakenValue is String) {
          final String lowerValue = isTakenValue.toLowerCase();
          taken =
              lowerValue == 'true' || lowerValue == '1' || lowerValue == 'yes';
        }
      }

      // Create full object hierarchy
      final medicine = Medicine(name: name, type: type, color: color);
      medicine.addSpecification(Specification(dosage: dosage, unit: unit));

      final treatmentPlan = TreatmentPlan(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        timeOfDay: DateTime(2023, 1, 1, 12, 0),
      );

      final treatment =
          Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

      // Create and return the intake log
      return IntakeLog(treatment, isTaken: taken);
    } catch (e) {
      // If anything fails, return a basic log
      'Error creating IntakeLog from map: $e'.log();
      final defaultMedicine = Medicine(name: 'Error Medicine', type: 'pill');
      defaultMedicine.addSpecification(Specification(dosage: 1.0, unit: 'mg'));

      final defaultPlan = TreatmentPlan(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        timeOfDay: DateTime(2023, 1, 1, 12, 0),
      );

      return IntakeLog(
        Treatment(medicine: defaultMedicine, treatmentPlan: defaultPlan),
      );
    }
  }
}

class JournalLog {
  final Map<DateTime, List<IntakeLog>> medicationLogs = {};

  // Constructor with no initialization as the map is already created as a final field
  // Data will be loaded when getMedicationsForTheDay is called
  JournalLog();

  /// Load medication logs from Hive storage
  Future<void> _loadMedicationLogs(DateTime date) async {
    date = date.normalize();
    try {
      final logs = await HiveService.getMedicationLogsForDate(date);

      if (logs != null && logs.isNotEmpty) {
        // Convert the logs back to IntakeLog objects with safer type handling
        final List<IntakeLog> intakeLogs = [];

        for (final dynamic logEntry in logs) {
          try {
            if (logEntry is Map) {
              // Create a Map<String, dynamic> from the potentially untyped Map
              final Map<String, dynamic> typedMap = {};
              logEntry.forEach((key, value) {
                if (key is String) {
                  typedMap[key] = value;
                }
              });

              if (typedMap.isNotEmpty) {
                intakeLogs.add(IntakeLog.fromMap(typedMap));
              }
            }
          } catch (parseError) {
            'Error parsing individual log entry: $parseError'.log();
            // Skip this entry and continue with others
          }
        }

        // Only update if we successfully parsed any logs
        if (intakeLogs.isNotEmpty) {
          medicationLogs[date] = intakeLogs;
          return;
        }
      }
    } catch (e) {
      // If there's an error, we'll fall back to sample data
      'Error loading medication logs: $e'.log();
    }

    // If we don't have stored logs or there was an error, use sample data
    if (!medicationLogs.containsKey(date) || medicationLogs[date]!.isEmpty) {
      final treatments = Treatment.getSample();
      medicationLogs[date] =
          treatments.map((treatment) => IntakeLog(treatment)).toList();
    }
  }

  /// Save medication logs to Hive storage
  Future<void> saveMedicationLogs(DateTime date) async {
    date = date.normalize();
    try {
      // Ensure we have valid data to save
      if (medicationLogs.containsKey(date) &&
          medicationLogs[date] != null &&
          medicationLogs[date]!.isNotEmpty) {
        // Convert each log to a map, handling any potential errors
        final List<Map<String, dynamic>> logs = [];

        for (final log in medicationLogs[date]!) {
          try {
            logs.add(log.toMap());
          } catch (mapError) {
            'Error converting log to map: $mapError'.log();
            // Continue with other logs
          }
        }

        // Only save if we have valid logs
        if (logs.isNotEmpty) {
          await HiveService.saveMedicationLogsForDate(date, logs);
        }
      }
    } catch (e) {
      'Error saving medication logs: $e'.log();
    }
  }

  Future<List<IntakeLog>> getMedicationsForTheDay(DateTime date) async {
    date = date.normalize();

    // Check if we already have logs for this date in memory
    if (!medicationLogs.containsKey(date) || medicationLogs[date]!.isEmpty) {
      await _loadMedicationLogs(date);
    }

    return medicationLogs[date] ?? [];
  }

  /// Calculate adherence rate based on in-memory data
  /// Note: This method doesn't load data from storage - call getMedicationsForTheDay
  /// for all relevant dates before using this method for accurate results
  double getAdherenceRate(
      Treatment treatment, DateTime startDate, DateTime endDate) {
    int takenCount = 0;
    int totalDays = 0;

    DateTime currentDate = startDate.normalize();

    while (!currentDate.isAfter(endDate)) {
      final hasMedsForDate = medicationLogs.containsKey(currentDate) &&
          medicationLogs[currentDate] != null &&
          medicationLogs[currentDate]!.isNotEmpty;

      if (hasMedsForDate) {
        for (final log in medicationLogs[currentDate]!) {
          if (log.treatment.medicine.name == treatment.medicine.name) {
            takenCount += log.isTaken ? 1 : 0;
            totalDays++;
          }
        }
      }

      // Increment day safely
      final nextDate = currentDate.add(const Duration(days: 1));
      currentDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
    }

    if (totalDays == 0) return 0.0;
    return takenCount / totalDays;
  }

  /// Asynchronous version of getAdherenceRate that loads data from storage
  Future<double> getAdherenceRateAsync(
      Treatment treatment, DateTime startDate, DateTime endDate) async {
    // Load data for each day in the range
    DateTime currentDate = startDate.normalize();
    while (!currentDate.isAfter(endDate)) {
      await getMedicationsForTheDay(currentDate);

      // Increment day safely
      final nextDate = currentDate.add(const Duration(days: 1));
      currentDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
    }

    // Use the synchronous version now that all data is loaded
    return getAdherenceRate(treatment, startDate, endDate);
  }
}
