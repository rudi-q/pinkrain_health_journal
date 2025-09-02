import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/util/helpers.dart';

import '../../../core/models/medicine_model.dart';
import '../../treatment/data/treatment.dart';
import '../../treatment/domain/treatment_manager.dart';

class IntakeLog {
  final Treatment treatment;
  bool isTaken;

  IntakeLog(this.treatment, {this.isTaken = false});

  /// Convert IntakeLog to a Map for storage
  Map<String, dynamic> toMap() {
    // Debug the ID being stored
    final treatmentId = treatment.id;
    if (treatmentId.isEmpty) {
      devPrint("WARNING: Empty treatment ID in toMap for ${treatment.medicine.name}");
    }

    return {
      'treatment_id': treatmentId,
      'medicine_name': treatment.medicine.name,
      'medicine_type': treatment.medicine.type,
      'medicine_color': treatment.medicine.color,
      'dosage': treatment.medicine.specs.dosage,
      'unit': treatment.medicine.specs.unit,
      'treatment_plan_start_date': treatment.treatmentPlan.startDate.toIso8601String(),
      'treatment_plan_end_date': treatment.treatmentPlan.endDate.toIso8601String(),
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
      final dynamic startDateValue = map['treatment_plan_start_date'];
      final dynamic endDateValue = map['treatment_plan_end_date'];
      final dynamic treatmentIdValue = map['treatment_id'];

      // Get treatment ID safely
      final String treatmentId = (treatmentIdValue is String) ? treatmentIdValue : '';
      if (treatmentId.isEmpty) {
        devPrint("WARNING: Empty treatment ID in fromMap for $nameValue");
      }

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
        } else if (dosageValue is String) {
          try {
            dosage = double.parse(dosageValue);
          } catch (e) {
            // Keep default
          }
        }
      }

      // Convert unit with safe default
      final String unit = (unitValue is String) ? unitValue : 'mg';

      // Convert taken status with safe default
      bool isTaken = false;
      if (isTakenValue != null) {
        if (isTakenValue is bool) {
          isTaken = isTakenValue;
        } else if (isTakenValue is int) {
          isTaken = isTakenValue != 0;
        } else if (isTakenValue is String) {
          isTaken = isTakenValue.toLowerCase() == 'true' ||
              isTakenValue == '1';
        }
      }

      DateTime startDate = DateTime.now();
      try {
        if (startDateValue is String) {
          startDate = DateTime.parse(startDateValue);
        }
      } catch (e) {
        // Default logic
      }

      DateTime endDate = startDate.add(const Duration(days: 7));
      try {
        if (endDateValue is String) {
          endDate = DateTime.parse(endDateValue);
        }
      } catch (e) {
        // Default logic
      }

      // Create a medicine object
      final medicine = Medicine(
        name: name,
        type: type,
        color: color,
      );

      // Add specification
      medicine.addSpecification(
        Specification(
          dosage: dosage,
          unit: unit,
          useCase: '',
        ),
      );

      // Create treatment plan
      final treatmentPlan = TreatmentPlan(
        startDate: startDate,
        endDate: endDate,
        mealOption: 'No preference',
        instructions: '',
        frequency: const Duration(days: 1),
        timeOfDay: DateTime(2023, 1, 1, 12, 0),
      );

      // Create the treatment with the explicit ID
      final treatment = Treatment(
        id: treatmentId,
        medicine: medicine, 
        treatmentPlan: treatmentPlan
      );

      // Log the ID we're using
      devPrint("Created treatment from map with ID: '$treatmentId'");

      return IntakeLog(treatment, isTaken: isTaken);
    } catch (e) {
      devPrint('Error in IntakeLog.fromMap: $e');
      // Create a fallback log entry
      final medicine = Medicine(name: 'Error Loading', type: 'pill', color: 'red')
        ..addSpecification(Specification(dosage: 0.0, unit: 'mg', useCase: ''));

      final plan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        timeOfDay: DateTime(2023, 1, 1, 12, 0),
      );

      final treatment = Treatment(medicine: medicine, treatmentPlan: plan);
      return IntakeLog(treatment);
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
      // First, try to load from storage
      final logs = await HiveService.getMedicationLogsForDate(date);

      // CRITICAL FIX: Always check for up-to-date treatment data
      final treatmentManager = TreatmentManager();
      await treatmentManager.loadTreatments(); // Ensure latest treatments are loaded
      final latestTreatments = treatmentManager.treatments;

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
                // Create the base IntakeLog
                final intakeLog = IntakeLog.fromMap(typedMap);

                // CRITICAL FIX: Update with the latest treatment data if it exists
                final treatmentId = intakeLog.treatment.id;
                final matchingTreatment = latestTreatments.firstWhere(
                  (t) => t.id == treatmentId,
                  orElse: () => intakeLog.treatment,
                );

                // Use the updated treatment but preserve the intake status
                final updatedIntakeLog = IntakeLog(matchingTreatment, isTaken: intakeLog.isTaken);
                intakeLogs.add(updatedIntakeLog);
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
      // If there's an error, we'll fall back to creating logs from current treatments
      'Error loading medication logs: $e'.log();
    }

    // If we don't have stored logs or there was an error, create logs for all current treatments
    if (!medicationLogs.containsKey(date) || medicationLogs[date]!.isEmpty) {
      // Instead of using sample data, use all current treatments from TreatmentManager
      final treatmentManager = TreatmentManager();
      await treatmentManager.loadTreatments(); // Ensure latest treatments are loaded
      final currentTreatments = treatmentManager.treatments;

      if (currentTreatments.isNotEmpty) {
        devPrint("Creating logs for ${currentTreatments.length} current treatments");
        medicationLogs[date] = 
            currentTreatments.map((treatment) => IntakeLog(treatment)).toList();
      } else {
        devPrint("No current treatments found, journal will be empty");
        medicationLogs[date] = [];
      }
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

  Future<List<IntakeLog>> getMedicationsForTheDay(DateTime date, {bool forceReload = false}) async {
    date = date.normalize();

    // Always reload from storage if force reload is requested
    if (forceReload || !medicationLogs.containsKey(date) || medicationLogs[date]!.isEmpty) {
      await _loadMedicationLogs(date);
      "Medications for ${date.toString()} loaded from storage (force: $forceReload)".log();
    } else {
      "Using cached medications for ${date.toString()}".log();
    }

    return medicationLogs[date] ?? [];
  }

  /// Mean adherence for *all* active treatments between the two dates.
  /// Counts every day in the interval for every treatment, even if no
  /// log entry exists (missed doses stay missed).
  ///
  /// Returns 0.0 if no treatments are present at all.
  double getAdherenceRateAll(DateTime startDate, DateTime endDate) {
    // Normalise the bounds to midnight so we step cleanly day-by-day.
    final DateTime start = DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime end   = DateTime(endDate.year,   endDate.month,   endDate.day);

    if (end.isBefore(start)) return 0.0;

    // 1️⃣  Figure out which treatments are *active* in this window.
    final Set<String> treatmentIds = <String>{};

    int takenDoseCount = 0;

    DateTime current = start;
    while (!current.isAfter(end)) {
      final logs = medicationLogs[current];
      if (logs != null && logs.isNotEmpty) {
        for (final log in logs) {
          treatmentIds.add(log.treatment.id);
          if (log.isTaken) takenDoseCount++;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    if (treatmentIds.isEmpty) return 0.0;

    // 2️⃣  Expected doses  =  (# days) × (# distinct treatments)
    final int daysInclusive      = end.difference(start).inDays + 1;
    final int expectedDoseCount  = treatmentIds.length * daysInclusive;

    final rawRate = takenDoseCount / expectedDoseCount;

    // Round to 4 decimals and turn back into a double:
    return (rawRate * 10000).round() / 10000;
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
          if (log.treatment.id == treatment.id) {
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

  /// Force reload medication logs for a specific date by clearing the cache
  Future<List<IntakeLog>> forceReloadMedicationLogs(DateTime date) async {
    date = date.normalize();
    // PERFORMANCE FIX: Only remove the specific date entry instead of clearing all
    medicationLogs.remove(date);

    // CRITICAL FIX: Ensure we get the most up-to-date treatments
    final treatmentManager = TreatmentManager();
    await treatmentManager.loadTreatments(); // Reload fresh from storage

    devPrint("Force reloading medication logs for ${date.toString().split(' ')[0]} with ${treatmentManager.treatments.length} current treatments");

    // Get the existing logs if any
    final existingLogs = await HiveService.getMedicationLogsForDate(date);
    bool needsUpdate = false;

    // Create a new list for this date
    final updatedLogs = <IntakeLog>[];

    if (existingLogs != null && existingLogs.isNotEmpty) {
      devPrint("Found ${existingLogs.length} existing logs for this date");

      // For each existing log, try to find the updated treatment
      for (final logMap in existingLogs) {
        final medicineName = logMap['medicine_name'] as String?;
        final isTaken = logMap['is_taken'] as bool? ?? false;
        String treatmentId = logMap['treatment_id'] as String? ?? '';

        devPrint("Processing journal entry for: $medicineName (ID: $treatmentId)");

        // First try to find by ID if present
        Treatment? updatedTreatment;
        if (treatmentId.isNotEmpty) {
          try {
            updatedTreatment = treatmentManager.treatments.firstWhere(
              (t) => t.id == treatmentId
            );
            devPrint("Found treatment by ID match: ${updatedTreatment.medicine.name}");
          } catch (e) {
            // No treatment found by ID
            devPrint("No treatment found with ID: $treatmentId");
          }
        }

        // If ID didn't match or was empty, try by name
        if (updatedTreatment == null && medicineName != null && medicineName.isNotEmpty) {
          try {
            updatedTreatment = treatmentManager.treatments.firstWhere(
              (t) => t.medicine.name.toLowerCase() == medicineName.toLowerCase()
            );
            devPrint("Found treatment by name match: ${updatedTreatment.medicine.name} with ID: ${updatedTreatment.id}");

            // If we found by name but ID is different, it's an update
            if (treatmentId != updatedTreatment.id) {
              devPrint("ID changed from '$treatmentId' to '${updatedTreatment.id}'");
              needsUpdate = true;
            }
          } catch (e) {
            devPrint("No treatment found with name: $medicineName");
          }
        }

        // If we found a treatment, create an updated log
        if (updatedTreatment != null) {
          final log = IntakeLog(updatedTreatment, isTaken: isTaken);
          updatedLogs.add(log);
          devPrint("Added log for ${updatedTreatment.medicine.name} with ID: ${updatedTreatment.id}");
        }
      }
    } else {
      // No existing logs, create new ones from all current treatments
      devPrint("No existing logs, creating new ones from current treatments");
      for (final treatment in treatmentManager.treatments) {
        final log = IntakeLog(treatment);
        updatedLogs.add(log);
        needsUpdate = true;
        devPrint("Created new log for ${treatment.medicine.name} with ID: ${treatment.id}");
      }
    }

    // Update our in-memory store
    medicationLogs[date] = updatedLogs;

    // If we made changes, save them
    if (needsUpdate || updatedLogs.length != (existingLogs?.length ?? 0)) {
      await saveMedicationLogs(date);
      devPrint("Saved updated medication logs with ${updatedLogs.length} entries");
    }

    return updatedLogs;
  }

  /// Clear all cached medication logs to force reload from storage
  void clearAllCachedMedicationLogs() {
    medicationLogs.clear();
  }
}
